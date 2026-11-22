# frozen_string_literal: true

module Feeds
  class PostJob < ApplicationJob
    include ReportsExhaustion

    queue_as :default
    limits_concurrency(
      to: 1,
      key: ->(subscription, _event) { subscription.id }
    )
    self.log_arguments = false

    discard_on ActiveJob::DeserializationError
    discard_on "Discordrb::Errors::UnknownChannel", "Discordrb::Errors::NoPermission" do |job, _error|
      subscription, event = job.arguments
      Ops::Notification::FeedPostFailure::Ensure.call(subscription:, channel_id: subscription.channel_for(event.type))
    end

    def perform(subscription, event)
      return log_skipped(event, "the subscription is no longer active") unless Subscription.active.exists?(subscription.id)
      return log_skipped(event, "the event expired") if event.expired?
      return log_skipped(event, "the story was already posted") if subscription.posts.exists?(story_key: event.story_key)

      pick = StoryPick.new(subscription:, event:)
      return log_skipped(event, "the server does not follow this kind of post or its filters, or followed it after it was published") unless pick.eligible?
      return log_skipped(event, "a better copy of the story is followed") unless pick.best?

      post_once(subscription, event)
    end

    private

    def post_once(subscription, event)
      StoryLock.hold(subscription.server_configuration, event.story_key) do
        next log_skipped(event, "the story was already posted") if subscription.posts.exists?(story_key: event.story_key)

        previous = CardOwnership.new.handed_off_post(subscription:, event:)
        if previous
          Ops::Feeds::Posts::HandOff.call(post: previous, subscription:, event:)
        else
          Ops::Feeds::Posts::Create.call(subscription:, event:)
        end
      end
    end

    def log_skipped(event, reason)
      Rails.logger.info { "#{self.class} skipped story #{event.story_key}: #{reason}." }
    end
  end
end
