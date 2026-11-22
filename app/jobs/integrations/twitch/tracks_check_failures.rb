# frozen_string_literal: true

module Integrations
  module Twitch
    module TracksCheckFailures
      private

      def report(error)
        Rails.logger.warn("Integrations: #{failure_label} check failed: #{error.class}: #{error.message}")
        failing_since = mark_failing
        case error
        when RateLimited then report_rate_limit(error)
        when Unauthorized then report_unauthorized(error)
        else report_broken_after(error, failing_since)
        end
      end

      def report_rate_limit(error)
        return unless NotifiesOwner.claim("#{failure_key}/rate_limited")

        ReportRateLimitJob.perform_later(failure_label, error.message, error.retry_after)
      end

      def report_unauthorized(error)
        ReportUnauthorizedJob.perform_later(error.message) if NotifiesOwner.claim("twitch/unauthorized")
      end

      def report_broken_after(error, failing_since)
        return if failing_since > Watch::BROKEN_AFTER.ago
        return unless NotifiesOwner.claim("#{failure_key}/broken")

        report_broken("#{error.class}: #{error.message}")
      end

      def mark_failing
        since = Rails.cache.read(failing_since_key) || Time.current
        Rails.cache.write(failing_since_key, since, expires_in: Watch::DORMANT_AFTER)
        since
      end

      def clear_failing
        Rails.cache.delete(failing_since_key)
      end

      def failing_since_key
        "integrations/#{failure_key}/failing_since"
      end

      def failure_label
        failure_key.humanize.tr("/", " ")
      end
    end
  end
end
