# frozen_string_literal: true

module Bot
  class CommandSetup < BaseEvent
    on :server_create

    def handle
      GuildCommandSync.new(event.bot).sync(event.server.id)
    end
  end
end
