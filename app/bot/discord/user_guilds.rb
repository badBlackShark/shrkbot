# frozen_string_literal: true

module Bot
  module Discord
    class UserGuilds
      PATH = "/users/@me/guilds?with_counts=true"

      def self.call(access_token)
        new(access_token).call
      end

      def initialize(access_token)
        @access_token = access_token
      end

      def call
        Rest.get_json(PATH, authorization: "Bearer #{@access_token}") do |json|
          json.map { |guild| Guild.from_api(guild) }
        end
      end
    end
  end
end
