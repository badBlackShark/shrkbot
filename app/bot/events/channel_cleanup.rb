# frozen_string_literal: true

module Bot
  class ChannelCleanup < BaseEvent
    include FindsServerConfiguration

    on :channel_delete

    def handle
      return unless server_configuration

      Ops::ServerConfiguration::ServerChannel::HandleDeletion.call(
        server_configuration:,
        channel_id: event.id,
        bot: event.bot
      )
    end
  end
end
