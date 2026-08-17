# frozen_string_literal: true

module Bot
  class ChannelUpsert < ChannelEvent
    on :channel_create, :channel_update

    private

    def apply
      return unless event.channel

      Ops::ServerConfiguration::ServerChannel::Upsert.call(
        server_configuration:,
        channel: GuildMetadata.channel_data(event.channel)
      )
    end
  end
end
