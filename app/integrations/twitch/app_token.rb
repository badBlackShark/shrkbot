# frozen_string_literal: true

module Integrations
  module Twitch
    class AppToken
      CACHE_KEY = "integrations/twitch/app_token"
      TOKEN_URL = "https://id.twitch.tv/oauth2/token"

      def value
        @value ||= Rails.cache.read(CACHE_KEY) || fetch
      end

      def invalidate!
        @value = nil
        Rails.cache.delete(CACHE_KEY)
      end

      private

      def fetch
        token, expires_in = Http.post_form(
          TOKEN_URL,
          form: {
            client_id: ENV.fetch("TWITCH_CLIENT_ID"),
            client_secret: ENV.fetch("TWITCH_CLIENT_SECRET"),
            grant_type: "client_credentials"
          },
          status_errors: {400 => Unauthorized, 403 => Unauthorized}
        ) do |body|
          [body.fetch("access_token"), body.fetch("expires_in")]
        end
        Rails.cache.write(CACHE_KEY, token, expires_in: [expires_in - 1.day.to_i, expires_in / 2].max)
        token
      end
    end
  end
end
