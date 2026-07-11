# frozen_string_literal: true

module Bot
  class ServerCleanup < BaseEvent
    on :server_delete

    def handle
      config = ::ServerConfiguration.find_by(discord_id: event.server)
      return unless config

      Ops::ServerConfiguration::Destroy.call(server_configuration: config)
    end
  end
end
