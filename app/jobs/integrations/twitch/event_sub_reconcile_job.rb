# frozen_string_literal: true

module Integrations
  module Twitch
    class EventSubReconcileJob < ApplicationJob
      ALERT_INTERVAL = 1.day
      REPEAT_WINDOW = 11.minutes
      MIN_RETRY = 1.minute

      queue_as :default
      limits_concurrency(
        to: 1,
        key: ->(*) { "twitch-eventsub-reconcile" },
        duration: 5.minutes,
        on_conflict: :discard
      )

      def perform(rebuild: false)
        return unless runnable?

        subscriptions = EventSubSubscriptions.new
        diff = EventSubDiff.new(existing: subscriptions.all, broadcaster_ids:, callback:, rebuild:)
        report(revocation_problems(diff.revoked))
        diff.stale.each { |subscription| subscriptions.destroy(subscription.id) }
        failures = diff.missing.filter_map { |wanted| create_failure(subscriptions, wanted) }
        report(creation_problems(failures).select { |key, _line| repeated?(key) })
      rescue RateLimited => error
        rate_limited(error, rebuild)
      rescue Error => error
        warn(error)
      end

      private

      def runnable?
        Client.configured? && EventSub.configured? && callback.start_with?("https://")
      end

      def callback
        @callback ||= Rails.application.routes.url_helpers.api_twitch_event_sub_url(host: ENV.fetch("WEB_BASE_URL"))
      end

      def broadcaster_ids
        Watch.demanded.where(watcher: ChannelWatcher.name).pluck(:external_id)
      end

      def create_failure(subscriptions, wanted)
        subscriptions.create(
          type: wanted.type,
          version: wanted.version,
          condition: {broadcaster_user_id: wanted.broadcaster_id},
          callback:
        )
        nil
      rescue RateLimited
        raise
      rescue Error => error
        [wanted, error]
      end

      def revocation_problems(revoked)
        revoked.group_by(&:status).map do |status, subscriptions|
          count = subscriptions.size
          [status, "Twitch revoked #{count} #{"subscription".pluralize(count)}: #{status}."]
        end
      end

      def creation_problems(failures)
        failures.group_by { |_wanted, error| "#{error.class}: #{error.message}" }.map do |key, group|
          count = group.size
          wanted = group.first.first
          [key, "Creating #{count} #{"subscription".pluralize(count)} failed (first: #{wanted.type} for channel #{wanted.broadcaster_id}): #{key}"]
        end
      end

      def rate_limited(error, rebuild)
        warn(error)
        self.class.set(wait: [error.retry_after.to_i.seconds, MIN_RETRY].max).perform_later(rebuild: true) if rebuild
        ReportRateLimitJob.perform_later("Twitch EventSub", error.message, error.retry_after) if claim_alert("RateLimited")
      end

      def warn(error)
        Rails.logger.warn("Integrations: Twitch EventSub reconcile failed: #{error.class}: #{error.message}")
      end

      def repeated?(key)
        !Rails.cache.write(cache_key("failure", key), true, unless_exist: true, expires_in: REPEAT_WINDOW)
      end

      def report(problems)
        lines = problems.filter_map { |key, line| line if claim_alert(key) }
        ReportEventSubJob.perform_later(lines) if lines.any?
      end

      def claim_alert(key)
        Rails.cache.write(cache_key("alert", key), true, unless_exist: true, expires_in: ALERT_INTERVAL)
      end

      def cache_key(kind, key)
        "integrations/twitch/eventsub/#{kind}/#{Digest::SHA256.hexdigest(key)}"
      end
    end
  end
end
