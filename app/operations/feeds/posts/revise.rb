# frozen_string_literal: true

module Ops
  module Feeds
    module Posts
      class Revise < ApplicationOperation
        self.transactional = false

        receives :post, :event

        def call
          return ok unless post.message_id && latest?

          ::Bot::Discord::Components.edit(channel_id: post.channel_id, message_id: post.message_id, rendered: announcement.card)
          ok
        rescue Discordrb::Errors::UnknownMessage, Discordrb::Errors::UnknownChannel, Discordrb::Errors::NoPermission
          post.update!(message_id: nil)
          ok
        end

        private

        def latest?
          ::Integrations::Event
            .where(watch_id: event.watch_id)
            .where("payload ->> 'story_key' = ?", post.story_key)
            .order(:occurred_at, :created_at, :id)
            .last == event
        end

        def announcement
          post.subscription.source.announcement(event:, subscription: post.subscription)
        end
      end
    end
  end
end
