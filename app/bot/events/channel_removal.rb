# frozen_string_literal: true

module Bot
  class ChannelRemoval < ChannelEvent
    on :channel_delete

    private

    def apply
      channel = server_configuration.server_channels.find_by(discord_id: event.id)
      return unless channel

      Ops::ServerConfiguration::ServerChannel::Destroy.call(server_channel: channel)
    end
  end
end
