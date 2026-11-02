# frozen_string_literal: true

require "json"

module Bot
  module Discord
    class OwnerUsername
      CACHE_KEY = "bot/discord/owner_username"
      TTL = 1.day
      FAILURE_TTL = 10.minutes

      def self.call
        cached = Rails.cache.read(CACHE_KEY)
        return cached.presence unless cached.nil?

        username = new.fetch
        Rails.cache.write(CACHE_KEY, username.to_s, expires_in: username ? TTL : FAILURE_TTL)
        username
      end

      def fetch
        return if Config.owner_id.blank?

        response = Rest.get("/users/#{Config.owner_id}", authorization: Config.rest_token)
        return JSON.parse(response.body).fetch("username") if response.code.to_i == 200

        warn_failed("Discord responded with #{response.code}")
      rescue *::Integrations::Http::TRANSPORT_ERRORS, KeyError => e
        warn_failed(e.message)
      end

      private

      def warn_failed(reason)
        Rails.logger.warn("Discord: owner username lookup failed: #{reason}")
        nil
      end
    end
  end
end
