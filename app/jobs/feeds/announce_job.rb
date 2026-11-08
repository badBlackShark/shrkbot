# frozen_string_literal: true

module Feeds
  class AnnounceJob < ApplicationJob
    include ReportsExhaustion
    include Integrations::Handler

    handles(*Feeds.sources.flat_map(&:announced_types).map(&:constantize))

    queue_as :default
    limits_concurrency(
      to: 1,
      key: ->(event) { event.watch_id }
    )

    discard_on ActiveJob::DeserializationError

    def perform(event)
      jobs = subscriptions(event).map { |subscription| PostJob.new(subscription, event) }
      ActiveJob.perform_all_later(jobs)
    end

    private

    def subscriptions(event)
      Subscription
        .demanding(source(event).post_type(event.type))
        .where(watch_id: event.watch_id)
        .where.not(id: Post.where(story_key: event.story_key).select(:subscription_id))
    end

    def source(event)
      Feeds.source_for_watcher(event.watch.watcher)
    end
  end
end
