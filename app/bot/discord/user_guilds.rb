# frozen_string_literal: true

require "json"

module Bot
  module Discord
    class UserGuilds
      PATH = "/users/@me/guilds?with_counts=true"

      class Error < StandardError
        attr_reader :status

        def initialize(message = nil, status: nil)
          super(message)
          @status = status
        end
      end

      class Unauthorized < Error
        def initialize(message = "Discord rejected the access token", status: 401)
          super
        end
      end

      def self.call(access_token)
        new(access_token).call
      end

      def self.rejection(status)
        return Unauthorized.new if status == 401

        Error.new("Discord responded with #{status}", status:)
      end

      def initialize(access_token)
        @access_token = access_token
      end

      def call
        response = Rest.get(PATH, authorization: "Bearer #{@access_token}")
        status = response.code.to_i
        raise self.class.rejection(status) unless status.between?(200, 299)

        JSON.parse(response.body).map { |guild| Guild.from_api(guild) }
      rescue *::Integrations::Http::TRANSPORT_ERRORS => e
        raise Error, e.message
      end
    end
  end
end
