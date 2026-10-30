# frozen_string_literal: true

module Ops
  module Feeds
    module Subscriptions
      class Create < ApplicationOperation
        receives :server_configuration, :watcher, :target, :channel_id, :event_types, :templates, :settings

        def call
          return failure(::Feeds::Subscription.cap_message(source)) if ::Feeds::Subscription.at_cap?(server_configuration, source)

          watch.assign_attributes(name: target.name, image_url: target.image_url)
          return failure(I18n.t("operations.feeds.subscriptions.already_followed", name: target.name)) if already_followed?
          return failure(subscription.errors.full_messages, value: subscription) unless subscription.valid?

          watch.save!
          subscription.save!
          ok(subscription)
        end

        private

        def source
          ::Feeds.source_for_watcher(watcher)
        end

        def watch
          @watch ||= ::Integrations::Watch.find_or_initialize_by(watcher:, external_id: target.external_id)
        end

        def already_followed?
          watch.persisted? && server_configuration.feed_subscriptions.exists?(watch:)
        end

        def subscription
          @subscription ||= server_configuration.feed_subscriptions.build(watch:, channel_id:).tap do |built|
            built.build_settings(settings)
            event_types.uniq.each { |event_type| built.follow(event_type, templates[event_type]) }
          end
        end
      end
    end
  end
end
