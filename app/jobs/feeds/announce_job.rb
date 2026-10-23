# frozen_string_literal: true

module Feeds
  class AnnounceJob < ApplicationJob
    include ReportsExhaustion

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
        .active
        .where(watch_id: event.watch_id)
        .where(id: SubscribedEvent.where(event_type: event.type).select(:subscription_id))
    end
  end
end
