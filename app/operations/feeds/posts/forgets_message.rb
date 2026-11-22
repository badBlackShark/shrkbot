# frozen_string_literal: true

module Ops
  module Feeds
    module Posts
      module ForgetsMessage
        private

        def forgetting_a_lost_card(post)
          yield
        rescue Discordrb::Errors::UnknownMessage
          forget_message(post)
        rescue Discordrb::Errors::UnknownChannel, Discordrb::Errors::NoPermission
          Ops::Notification::FeedPostFailure::Ensure.call(subscription: post.subscription, channel_id: post.channel_id)
          forget_message(post)
        end

        def forget_message(post)
          post.update!(message_id: nil, retracted_at: nil)
          ok
        end
      end
    end
  end
end
