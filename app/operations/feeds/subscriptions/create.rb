# frozen_string_literal: true

module Ops
  module Feeds
    module Subscriptions
      class Create < ApplicationOperation
        receives :server_configuration, :watcher, :target, :channel_id, :body_length, :event_types, :templates
        receives :role_id, optional: true

        def call
          return failure(I18n.t("operations.feeds.subscriptions.cap", max: ::Feeds::Subscription::MAX_PER_SERVER)) if ::Feeds::Subscription.at_cap?(server_configuration)

          watch.assign_attributes(name: target.name, image_url: target.image_url)
          return failure(I18n.t("operations.feeds.subscriptions.already_followed", name: target.name)) if already_followed?
          return failure(subscription.errors.full_messages, value: subscription) unless subscription.valid?

          watch.save!
          subscription.save!
          ok(subscription)
        end

        private

        def watch
          @watch ||= ::Integrations::Watch.find_or_initialize_by(watcher:, external_id: target.external_id)
        end

        def already_followed?
          watch.persisted? && server_configuration.feed_subscriptions.exists?(watch:)
        end

        def subscription
          @subscription ||= server_configuration.feed_subscriptions.build(
            watch:,
            channel_id:,
            role_id: role_id.presence,
            body_length:
          ).tap do |built|
            event_types.uniq.each { |event_type| built.follow(event_type, templates[event_type]) }
          end
        end
      end
    end
  end
end
