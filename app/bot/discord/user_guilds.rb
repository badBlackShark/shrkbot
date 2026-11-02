# frozen_string_literal: true

require "json"

module Bot
  module Discord
    class UserGuilds
      PATH = "/users/@me/guilds?with_counts=true"

      class Error < StandardError; end

      class Unauthorized < Error; end

      def self.call(access_token)
        new(access_token).call
      end

      def initialize(access_token)
        @access_token = access_token
      end

      def call
        response = Rest.get(PATH, authorization: "Bearer #{@access_token}")
        raise Unauthorized, "Discord rejected the access token" if response.code.to_i == 401
        unless response.code.to_i.between?(200, 299)
          raise Error, "Discord responded with #{response.code}"
        end

        JSON.parse(response.body).map { |guild| Guild.from_api(guild) }
      rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, JSON::ParserError => e
        raise Error, e.message
      end
    end
  end
end
