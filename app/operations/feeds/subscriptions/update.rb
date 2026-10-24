# frozen_string_literal: true

module Ops
  module Feeds
    module Subscriptions
      class Update < ApplicationOperation
        receives :subscription, :channel_id, :body_length, :event_types, :templates
        receives :role_id, optional: true

        def call
          subscription.assign_attributes(channel_id:, role_id: role_id.presence, body_length:)
          update_followed_events
          build_missing_events
          return failure(subscription.errors.full_messages, value: subscription) unless subscription.valid?

          subscription.save!
          ok(subscription)
        end

        private

        def update_followed_events
          subscription.subscribed_events.each do |event|
            if event_types.include?(event.event_type)
              event.template = ::Feeds::Templates.custom(event.event_type, templates[event.event_type])
            else
              event.mark_for_destruction
            end
          end
        end

        def build_missing_events
          followed = subscription.subscribed_events.map(&:event_type)
          (event_types.uniq - followed).each { |event_type| subscription.follow(event_type, templates[event_type]) }
        end
      end
    end
  end
end
