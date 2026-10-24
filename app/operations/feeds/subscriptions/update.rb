# frozen_string_literal: true

module Ops
  module Feeds
    module Subscriptions
      class Update < ApplicationOperation
        receives :subscription, :channel_id, :body_length, :event_types
        receives :role_id, optional: true

        def call
          subscription.assign_attributes(channel_id:, role_id: role_id.presence, body_length:)
          mark_unfollowed_events
          build_missing_events
          return failure(subscription.errors.full_messages, value: subscription) unless subscription.valid?

          subscription.save!
          ok(subscription)
        end

        private

        def mark_unfollowed_events
          subscription.subscribed_events.each do |event|
            event.mark_for_destruction unless event_types.include?(event.event_type)
          end
        end

        def build_missing_events
          followed = subscription.subscribed_events.map(&:event_type)
          (event_types.uniq - followed).each do |event_type|
            subscription.subscribed_events.build(event_type:)
          end
        end
      end
    end
  end
end
