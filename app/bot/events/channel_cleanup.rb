# frozen_string_literal: true

module Bot
  class ChannelCleanup < BaseEvent
    on :channel_delete

    def handle
      return unless event.server

      config = ServerConfiguration.find_by(discord_id: event.server.id)
      return unless config

      Ops::ServerConfiguration::Channels::HandleDeletion.call(
        server_configuration: config,
        channel_id: event.id,
        bot: event.bot
      )
    end
  end
end
