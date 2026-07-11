# frozen_string_literal: true

module Bot
  class CommandBackfill < BaseEvent
    on :ready

    def handle
      syncer = GuildCommandSync.new(event.bot)
      event.bot.servers.keys.each { |discord_id| syncer.sync(discord_id) }
    end
  end
end
