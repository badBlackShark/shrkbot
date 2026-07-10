# frozen_string_literal: true

class CommandBackfill < BaseEvent
  on :ready

  def handle
    syncer = GuildCommandSync.new(event.bot)
    event.bot.servers.keys.each { |discord_id| syncer.sync(discord_id) }
  end
end
