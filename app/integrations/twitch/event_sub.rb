# frozen_string_literal: true

module Integrations
  module Twitch
    module EventSub
      MAX_AGE = 10.minutes

      def self.configured?
        ENV["TWITCH_EVENTSUB_SECRET"].present?
      end

      def self.secret
        ENV.fetch("TWITCH_EVENTSUB_SECRET")
      end

      def self.verified?(message_id:, timestamp:, body:, signature:, now: Time.current)
        return false unless configured? && [message_id, timestamp, signature].all?(&:present?)

        sent_at = parse(timestamp)
        return false unless sent_at && (now - sent_at).abs <= MAX_AGE

        ActiveSupport::SecurityUtils.secure_compare(sign(message_id + timestamp + body), signature)
      end

      def self.sign(message)
        "sha256=#{OpenSSL::HMAC.hexdigest("SHA256", secret, message)}"
      end
      private_class_method :sign

      def self.parse(timestamp)
        Time.iso8601(timestamp)
      rescue ArgumentError
        nil
      end
      private_class_method :parse
    end
  end
end
