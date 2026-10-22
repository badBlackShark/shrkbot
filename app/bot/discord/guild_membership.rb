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

      def user_member?(guild_id, user_id)
        Discordrb::API::Server.resolve_member(Config.rest_token, guild_id, user_id)
        true
      rescue Discordrb::Errors::UnknownMember, Discordrb::Errors::UnknownUser
        false
      end
    end
  end
end
