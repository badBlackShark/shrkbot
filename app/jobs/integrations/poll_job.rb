# frozen_string_literal: true

module Integrations
  class PollJob < ApplicationJob
    queue_as :default
    limits_concurrency(
      to: 1,
      key: ->(watcher) { watcher },
      duration: 1.hour,
      on_conflict: :discard
    )

    def perform(watcher)
      Watch.due.where(watcher:).find_each do |watch|
        poll(watch)
      rescue RateLimited => error
        record_failure(watch, error)
        break
      rescue => error
        record_failure(watch, error)
      end
    end

    private

    def poll(watch)
      events = watch.watcher_class.new(watch).observe
      Ops::Integrations::Watches::RecordObservation.call(watch:, events:)
    end

    def record_failure(watch, error)
      Rails.logger.warn("Integrations: #{watch.watcher} #{watch.external_id} failed: #{error.class}: #{error.message}")
      Rails.logger.error(error.full_message(highlight: false)) unless error.is_a?(Error)
      Ops::Integrations::Watches::RecordFailure.call(watch: watch.reload, error:)
    end
  end
end
