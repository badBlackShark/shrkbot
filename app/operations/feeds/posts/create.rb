# frozen_string_literal: true

module Ops
  module Feeds
    module Posts
      class Create < ApplicationOperation
        self.transactional = false

        receives :subscription, :event

        def call
          post = subscription.posts.create!(story_key: event.story_key)
          message_id = send_announcement(post)
          post.update!(channel_id: subscription.channel_id, message_id:)
          Rails.logger.info { "#{self.class} posted story #{event.story_key} to subscription #{subscription.id} as message #{message_id} in channel #{subscription.channel_id}." }
          ok(post)
        end

        private

        def send_announcement(post)
          ::Bot::Discord::Components.create_with_subject(
            channel_id: subscription.channel_id,
            subject: announcement.subject,
            rendered: announcement.card,
            allowed_mentions: announcement.allowed_mentions,
            fallback: announcement.fallback,
            attachments: announcement.attachments
          )
        rescue
          post.destroy!
          raise
        end

        def announcement
          @announcement ||= subscription.source.announcement(event:, subscription:)
        end
      end
    end
  end
end
