# frozen_string_literal: true

module Feeds
  class ReviseJob < ApplicationJob
    include ReportsExhaustion
    include Integrations::Handler

    handles Integrations::Twitch::StreamUpdated, Integrations::Twitch::StreamSampled, Integrations::Twitch::StreamEnded

    queue_as :default
    limits_concurrency(
      to: 1,
      key: ->(event) { event.watch_id }
    )

    discard_on ActiveJob::DeserializationError

    def perform(event)
      jobs = posts(event).map { |post| RevisePostJob.new(post, event) }
      ActiveJob.perform_all_later(jobs)
    end

    private

    def posts(event)
      Post
        .where(
          story_key: event.story_key,
          subscription_id: Subscription.active.where(watch_id: event.watch_id).select(:id)
        )
        .where.not(message_id: nil)
    end
  end
end
