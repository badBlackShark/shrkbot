class ServerBackfill < BaseEvent
  on :ready

  def handle
    event.bot.servers.each_value { |server| GuildMetadata.sync(server, event.bot) }
  end
end
