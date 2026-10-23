# frozen_string_literal: true

module Feeds
  class AnnounceJob < ApplicationJob
    queue_as :default

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
