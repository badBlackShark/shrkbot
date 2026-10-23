# frozen_string_literal: true

module Feeds
  class PostJob < ApplicationJob
    queue_as :default
    limits_concurrency(
      to: 1,
      key: ->(subscription, event) { "#{subscription.id}-#{event.story_key}" }
    )
    self.log_arguments = false

    retry_on StandardError, wait: :polynomially_longer, attempts: 5
    discard_on ActiveJob::DeserializationError
    discard_on "Discordrb::Errors::UnknownChannel"
    discard_on "Discordrb::Errors::NoPermission"

    def perform(subscription, event)
      return log_skipped(event, "the story was already posted") if subscription.posts.exists?(story_key: event.story_key)
      return log_skipped(event, "a better copy of the story is subscribed") unless StoryPick.new(subscription:, event:).best?

      Ops::Feeds::Posts::Create.call(subscription:, event:)
    end

    private

    def log_skipped(event, reason)
      Rails.logger.info { "#{self.class} skipped story #{event.story_key}: #{reason}." }
    end
  end
end
