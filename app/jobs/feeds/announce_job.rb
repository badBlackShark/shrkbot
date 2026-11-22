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
      Feeds.sources
        .select { |source| source.announced_types.include?(event.type) }
        .map { |source| source.subscriptions_for(event).demanding(source.post_type(event.type)) }
        .reduce(:or)
        .where.not(id: Post.where(story_key: event.story_key).select(:subscription_id))
    end
  end
end
