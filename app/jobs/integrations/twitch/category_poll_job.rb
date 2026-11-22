# frozen_string_literal: true

module Integrations
  module Twitch
    class CategoryPollJob < ApplicationJob
      include TracksCheckFailures

      queue_as :default
      limits_concurrency(
        to: 1,
        key: ->(*) { "twitch-category-poll" },
        duration: 2.minutes,
        on_conflict: :discard
      )

      def perform
        return unless Client.configured?

        watches = CategoryWatcher.followed.to_a
        return if watches.empty?

        streams = fetch_streams(watches)&.uniq(&:user_id)
        return if streams.nil?

        transition(streams)
      end

      private

      def fetch_streams(watches)
        watches.flat_map { |watch| fetch(watch) }
      rescue RateLimited, Unauthorized => error
        report(error)
        nil
      end

      def fetch(watch)
        streams = CategoryStreams.new.refresh(watch.external_id)
        clear_category_failure(watch)
        streams
      rescue RateLimited, Unauthorized
        raise
      rescue Error => error
        Rails.logger.warn("Integrations: Twitch category #{watch.label} check failed: #{error.class}: #{error.message}")
        Ops::Integrations::Watches::RecordFailure.call(watch:, error:)
        []
      end

      def clear_category_failure(watch)
        return unless watch.failing_since

        Ops::Integrations::Watches::RecordObservation.call(watch:, events: [])
      end

      def transition(streams)
        watches = Ops::Integrations::Twitch::Watches::Discover.call(streams:).value
        clear_failing
        observations = CategorySighting.new(streams:, watches:).observations
        Ops::Integrations::Twitch::Streams::TransitionAll.call(observations:)
      rescue Error => error
        report(error)
      end

      def failure_key
        "twitch/categories"
      end

      def failure_label
        "Twitch categories"
      end

      def report_broken(message)
        ReportCategoryCheckBrokenJob.perform_later(message)
      end
    end
  end
end
