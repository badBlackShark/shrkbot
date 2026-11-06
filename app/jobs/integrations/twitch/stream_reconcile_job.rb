# frozen_string_literal: true

module Integrations
  module Twitch
    class StreamReconcileJob < ApplicationJob
      FAILING_SINCE_KEY = "integrations/twitch/streams/failing_since"

      queue_as :default
      limits_concurrency(
        to: 1,
        key: ->(*) { "twitch-stream-reconcile" },
        duration: 10.minutes,
        on_conflict: :discard
      )

      def perform
        return unless Client.configured?

        watches = ChannelWatcher.followed_for_live.to_a
        return if watches.empty?

        live = fetch_live(watches)
        return if live.nil?

        transition_all(watches, live)
      end

      private

      def fetch_live(watches)
        live = Streams.new.live(watches.map(&:external_id)).index_by(&:user_id)
        clear_failing
        live
      rescue Error => error
        report(error)
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
        rescue Error => error
          Rails.logger.warn("Integrations: Twitch stream transition for #{watch.label} failed, the next reconcile retries: #{error.class}: #{error.message}")
        rescue => error
          log_bug(watch, error)
          bugs << "#{watch.label}: #{error.class}: #{error.message}" if NotifiesOwner.claim("twitch/streams/bug/#{watch.id}/#{error.class}")
        end
        ReportPollBugsJob.perform_later(bugs) if bugs.any?
      end

      def log_bug(watch, error)
        Rails.logger.error("Integrations: Twitch stream transition for #{watch.label} failed: #{error.full_message(highlight: false)}")
      end

      def report(error)
        Rails.logger.warn("Integrations: Twitch stream reconcile failed: #{error.class}: #{error.message}")
        report_rate_limit(error) if error.is_a?(RateLimited)
        report_unauthorized(error) if error.is_a?(Unauthorized)
        report_broken(error) if mark_failing <= Watch::BROKEN_AFTER.ago
      end

      def report_rate_limit(error)
        return unless NotifiesOwner.claim("twitch/streams/rate_limited")

        ReportRateLimitJob.perform_later("Twitch streams", error.message, error.retry_after)
      end

      def report_unauthorized(error)
        ReportUnauthorizedJob.perform_later(error.message) if NotifiesOwner.claim("twitch/unauthorized")
      end

      def report_broken(error)
        ReportLiveCheckBrokenJob.perform_later("#{error.class}: #{error.message}") if NotifiesOwner.claim("twitch/streams/broken")
      end

      def mark_failing
        since = Rails.cache.read(FAILING_SINCE_KEY) || Time.current
        Rails.cache.write(FAILING_SINCE_KEY, since, expires_in: Watch::DORMANT_AFTER)
        since
      end

      def clear_failing
        Rails.cache.delete(FAILING_SINCE_KEY)
      end
    end
  end
end
