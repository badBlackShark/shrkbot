# frozen_string_literal: true

class ChannelSync < BaseEvent
  on :channel_create, :channel_update, :channel_delete

  def handle
    return unless event.server

    config = ServerConfiguration.find_by(discord_id: event.server.id)
    return unless config

    Ops::ServerConfiguration::ServerChannels::Sync.call(server_configuration: config, channels: GuildMetadata.channels(event.server))
  end
end
