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
        errors = []
        streams = watches.flat_map { |watch| fetch(watch, errors) }
        return streams if errors.size < watches.size

        report(errors.first)
        nil
      rescue RateLimited => error
        report(error)
        nil
      end

      def fetch(watch, errors)
        CategoryStreams.new.refresh(watch.external_id)
      rescue RateLimited
        raise
      rescue Error => error
        Rails.logger.warn("Integrations: Twitch category #{watch.label} check failed: #{error.class}: #{error.message}")
        errors << error
        []
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

      def report_broken(message)
        ReportCategoryCheckBrokenJob.perform_later(message)
      end
    end
  end
end
