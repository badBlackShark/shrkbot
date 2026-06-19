class RoleSync < BaseEvent
  on :server_role_create, :server_role_update, :server_role_delete

  def handle
    return unless event.server

    config = ServerConfiguration.find_by(discord_id: event.server.id)
    return unless config

    Ops::ServerConfiguration::ServerRoles::Sync.call(server_configuration: config, roles: GuildMetadata.roles(event.server))
  end
end
