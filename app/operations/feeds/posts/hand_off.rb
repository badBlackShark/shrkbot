# frozen_string_literal: true

module Ops
  module Feeds
    module Posts
      class HandOff < ApplicationOperation
        self.transactional = false

        receives :post, :subscription, :event

        def call
          post.reload
          return ok unless post.message_id

          target = ::Feeds::Post.find_or_initialize_by(subscription:, story_key: post.story_key)
          return ok if target.message_id

          transfer(target)
          Rails.logger.info { "#{self.class} moved story #{post.story_key} from subscription #{post.subscription_id} to #{subscription.id} as message #{target.message_id}." }
          ok(target)
        rescue Discordrb::Errors::UnknownMessage
          forget_message
        rescue Discordrb::Errors::UnknownChannel, Discordrb::Errors::NoPermission
          Ops::Notification::FeedPostFailure::Ensure.call(subscription: post.subscription, channel_id: post.channel_id)
          forget_message
        end

        private

        def transfer(target)
          ::Bot::Discord::Components.edit(
            channel_id: post.channel_id,
            message_id: post.message_id,
            rendered: subscription.source.announcement(event:, subscription:).card
          )
          target.update!(channel_id: post.channel_id, message_id: post.message_id, retracted_at: nil)
          post.update!(message_id: nil, retracted_at: nil)
        end

        def forget_message
          post.update!(message_id: nil, retracted_at: nil)
          ok
        end
      end
    end
  end
end
