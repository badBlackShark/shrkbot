# frozen_string_literal: true

class CommandSetup < BaseEvent
  on :server_create

  def handle
    GuildCommandSync.new(event.bot).sync(event.server.id)
  end
end
