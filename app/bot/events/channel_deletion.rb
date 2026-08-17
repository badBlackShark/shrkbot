# frozen_string_literal: true

module Bot
  class ChannelDeletion < ChannelEvent
    on :channel_delete

    private

    # ReleaseFromPlugins reads the deleted channel's name off the local row for
    # its notification, so it has to run before Destroy takes that row away.
    def apply
      Ops::ServerConfiguration::ServerChannel::ReleaseFromPlugins.call(
        server_configuration:,
        channel_id: event.id,
        bot: event.bot
      )
      destroy_local_row
    end

    def destroy_local_row
      channel = server_configuration.server_channels.find_by(discord_id: event.id)
      return unless channel

      Ops::ServerConfiguration::ServerChannel::Destroy.call(server_channel: channel)
    end
  end
end
