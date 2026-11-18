# frozen_string_literal: true

module Bot
  module Discord
    class OwnerUsername
      CACHE_KEY = "bot/discord/owner_username"
      TTL = 1.day
      FAILURE_TTL = 10.minutes

      def self.call
        new.call
      end

      def call
        cached = Rails.cache.read(CACHE_KEY)
        return cached.presence unless cached.nil?

        username = fetch
        Rails.cache.write(CACHE_KEY, username.to_s, expires_in: username ? TTL : FAILURE_TTL)
        username
      end

      private

      def fetch
        return if Config.owner_id.blank?

        Rest.get_json("/users/#{Config.owner_id}", authorization: Config.rest_token) { |json| json.fetch("username") }
      rescue ::Integrations::Error => e
        warn_failed(e.message)
      end

      def warn_failed(reason)
        Rails.logger.warn("Discord: owner username lookup failed: #{reason}")
        nil
      end
    end
  end
end
