class ServerSetup < BaseEvent
  on :server_create

  def handle
    Ops::ServerConfiguration::Ensure.call(discord_id: event.server.id)
  end
end
