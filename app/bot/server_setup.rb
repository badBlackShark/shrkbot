# frozen_string_literal: true

class ServerSetup < BaseEvent
  on :server_create

  def handle
    GuildMetadata.sync(event.server, event.bot)
  end
end
