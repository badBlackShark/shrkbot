# frozen_string_literal: true

module Bot
  class RoleEvent < BaseEvent
    def handle
      config = server_configuration
      return unless config

      apply(config)
      Ops::ServerConfiguration::BotRolePosition::Sync.call(
        server_configuration: config,
        position: GuildMetadata.bot_role_position(event.server, event.bot)
      )
    end

    private

    def apply(config)
      raise AbstractMethodError, "#{self.class} must implement #apply"
    end

    def server_configuration
      return unless event.server

      ::ServerConfiguration.find_by(discord_id: event.server.id)
    end
  end
end
