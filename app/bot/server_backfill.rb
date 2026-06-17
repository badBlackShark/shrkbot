class ServerBackfill < BaseEvent
  on :ready

  # discordrb suppresses server_create for guilds the bot is already in at startup
  # (GUILD_CREATE with unavailable: false returns before the event is raised), so
  # the live-join ServerSetup handler never sees them. Sweep them once on ready.
  def handle
    event.bot.servers.each_value do |server|
      Ops::ServerConfiguration::Ensure.call(discord_id: server.id)
    end
  end
end
