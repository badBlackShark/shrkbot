# frozen_string_literal: true

module Integrations
  class PollJob < ApplicationJob
    queue_as :default
    limits_concurrency(to: 1, key: ->(watch) { watch.watcher.deconstantize })

    discard_on ActiveJob::DeserializationError

    def perform(watch)
      events = watch.watcher_class.new(watch).observe
      Ops::Integrations::Watches::RecordObservation.call(watch:, events:)
    rescue Integrations::Error => error
      log_failure(watch, error)
      Ops::Integrations::Watches::RecordFailure.call(watch:, error:)
    end

    private

    def log_failure(watch, error)
      Rails.logger.warn("Integrations: #{watch.watcher} #{watch.external_id} failed: #{error.class}: #{error.message}")
    end
  end
end
