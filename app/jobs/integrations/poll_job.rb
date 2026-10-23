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
      bugs = []
      Watch.due.demanded.where(watcher:).find_each do |watch|
        poll(watch)
      rescue RateLimited => error
        record_failure(watch, error)
        break
      rescue => error
        failed = record_failure(watch, error)
        bugs << "#{failed.label}: #{failed.last_error}" if failed && new_bug?(watch, error)
      end
      ReportPollBugsJob.perform_later(bugs) if bugs.any?
    end

    private

    def poll(watch)
      events = watch.watcher_class.new(watch).observe
      Ops::Integrations::Watches::RecordObservation.call(watch:, events:)
    end

    def new_bug?(watch, error)
      !error.is_a?(Error) && !watch.last_error.to_s.start_with?("#{error.class}:")
    end

    def record_failure(watch, error)
      Rails.logger.warn("Integrations: #{watch.watcher} #{watch.external_id} failed: #{error.class}: #{error.message}")
      Rails.logger.error(error.full_message(highlight: false)) unless error.is_a?(Error)
      current = Watch.find_by(id: watch.id)
      return if current.nil?

      Ops::Integrations::Watches::RecordFailure.call(watch: current, error:)
      current
    end
  end
end
