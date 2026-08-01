# frozen_string_literal: true

module Bot
  module FindsServerConfiguration
    private

    def server_configuration
      return @server_configuration if defined?(@server_configuration)

      @server_configuration = event.server && ::ServerConfiguration.find_by(discord_id: event.server.id)
    end
  end
end
