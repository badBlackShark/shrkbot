# frozen_string_literal: true

module Ops
  module Feeds
    module Posts
      class Create < ApplicationOperation
        self.transactional = false

        receives :subscription, :event

        def call
          message_id = ::Bot::Discord::Components.create_message(
            channel_id: subscription.channel_id,
            content: announcement.subject,
            allowed_mentions:
          )
          ::Bot::Discord::Components.convert_to_v2(subscription.channel_id, message_id, announcement.card)
          post = subscription.posts.create!(
            story_key: event.story_key,
            event_id: event.id,
            discord_channel_id: subscription.channel_id,
            discord_message_id: message_id
          )
          Rails.logger.info { "#{self.class} posted story #{event.story_key} to subscription #{subscription.id} as message #{message_id} in channel #{subscription.channel_id}." }
          ok(post)
        end

        private

        def announcement
          @announcement ||= ::Feeds::Announcement.new(event:, subscription:)
        end

        def allowed_mentions
          subscription.role_id ? {parse: [], roles: [subscription.role_id]} : {parse: []}
        end
      end
    end
  end
end
