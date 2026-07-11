# frozen_string_literal: true

module Bot
  class ServerSetup < BaseEvent
    on :server_create

    def handle
      GuildMetadata.sync(event.server, event.bot)
    end
  end
end
