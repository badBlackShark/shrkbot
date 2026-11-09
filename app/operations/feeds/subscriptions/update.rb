# frozen_string_literal: true

module Ops
  module Feeds
    module Subscriptions
      class Update < ApplicationOperation
        receives :subscription, :channel_id, :event_types, :templates, :notifications, :settings

        def call
          subscription.assign_attributes(channel_id:)
          subscription.settings.assign_attributes(settings)
          update_followed_events
          build_missing_events
          return failure(I18n.t("operations.feeds.subscriptions.no_event_types"), value: subscription) if event_types.empty?
          return failure(subscription.errors.full_messages, value: subscription) unless subscription.valid?

          subscription.save!
          ok(subscription)
        end

        private

        def update_followed_events
          subscription.subscribed_events.each do |event|
            event.template = ::Feeds::Templates.custom(templates[event.event_type])
            event.notification_template = ::Feeds::Templates.notification(
              notifications[event.event_type],
              subscription.source.default_notification(event.event_type)
            )
          end
          subscription.subscribed_events.each do |event|
            event.mark_for_destruction unless event_types.include?(event.event_type)
          end
        end

        def build_missing_events
          followed = subscription.subscribed_events.map(&:event_type)
          (event_types.uniq - followed).each do |event_type|
            subscription.follow(event_type, template: templates[event_type], notification: notifications[event_type])
          end
        end
      end
    end
  end
end
