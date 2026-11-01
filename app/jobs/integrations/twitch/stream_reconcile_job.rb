# frozen_string_literal: true

module Integrations
  module Twitch
    class StreamReconcileJob < ApplicationJob
      include RecordsWatchFailures

      WATCHER = "Integrations::Twitch::ChannelWatcher"

      queue_as :default
      limits_concurrency(
        to: 1,
        key: ->(*) { "twitch-stream-reconcile" },
        duration: 10.minutes,
        on_conflict: :discard
      )

      def perform
        return unless Client.configured?

        watches = Watch.demanded.where(watcher: WATCHER).to_a
        return if watches.empty?

        live = fetch_live(watches)
        return if live.nil?

        Ops::Integrations::Watches::RecordPolls.call(watches:)
        transition_all(watches, live)
      end

      private

      def fetch_live(watches)
        Streams.new.live(watches.map(&:external_id)).index_by(&:user_id)
      rescue Error => error
        report(watches, error)
        nil
      end

      def transition_all(watches, live)
        bugs = []
        watches.each do |watch|
          stream = live[watch.external_id]
          Ops::Integrations::Twitch::Streams::Transition.call(
            watch:,
            observation: stream ? Live.from_stream(stream) : Offline.new
          )
        rescue => error
          failed = record_failure(watch, error)
          bugs << "#{failed.label}: #{failed.last_error}" if failed && new_bug?(watch, error)
        end
        ReportPollBugsJob.perform_later(bugs) if bugs.any?
      end

      def report(watches, error)
        Rails.logger.warn("Integrations: Twitch stream reconcile failed: #{error.class}: #{error.message}")
        if error.is_a?(RateLimited) && watches.all? { |watch| new_error?(watch, error) }
          ReportRateLimitJob.perform_later("Twitch streams", error.message, error.retry_after)
        end
        watches.each { |watch| Ops::Integrations::Watches::RecordFailure.call(watch:, error:) }
      end
    end
  end
end
