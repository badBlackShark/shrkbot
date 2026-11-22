# frozen_string_literal: true

module Feeds
  class CardOwnership
    class << self
      def handed_off_post(subscription:, event:)
        channel_id = subscription.channel_for(event.type)

        Post
          .joins(:subscription)
          .where(feed_subscriptions: {server_configuration_id: subscription.server_configuration_id})
          .where(story_key: event.story_key, channel_id:)
          .where.not(message_id: nil)
          .where.not(subscription_id: subscription.id)
          .includes(subscription: [:watch, :twitch_settings, :twitch_category_settings])
          .find { |post| !post.subscription.source.accepts?(post.subscription, event) }
      end

      def successor(post:, event:)
        candidates(post, event)
          .find { |candidate| StoryPick.new(subscription: candidate, event:).eligible? }
      end

      private

      def candidates(post, event)
        Feeds.sources
          .select { |source| source.announced_types.include?(event.type) }
          .map { |source| source.subscriptions_for(event).demanding(source.post_type(event.type)).posting_to(post.channel_id, source.post_type(event.type)) }
          .reduce(:or)
          .where(server_configuration_id: post.subscription.server_configuration_id)
          .where.not(id: post.subscription_id)
          .where.not(id: Post.where(story_key: post.story_key).where.not(message_id: nil).select(:subscription_id))
          .preload(:watch, :subscribed_events, :twitch_settings, :twitch_category_settings)
      end
    end
  end
end
