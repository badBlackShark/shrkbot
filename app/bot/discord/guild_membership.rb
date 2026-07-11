# frozen_string_literal: true

module Bot
  module Discord
    module GuildMembership
      module_function

      def member?(guild_id)
        Discordrb::API::Server.resolve(Config.rest_token, guild_id)
        true
      rescue Discordrb::Errors::UnknownServer, Discordrb::Errors::NoPermission
        false
      end
    end
  end
end
