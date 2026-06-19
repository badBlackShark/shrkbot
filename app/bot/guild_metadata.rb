module GuildMetadata
  module_function

  def sync(server, bot)
    config = Ops::ServerConfiguration::Ensure.call(discord_id: server.id).value
    Ops::ServerConfiguration::ServerChannels::Sync.call(server_configuration: config, channels: channels(server))
    Ops::ServerConfiguration::ServerRoles::Sync.call(server_configuration: config, roles: roles(server))
    Ops::ServerConfiguration::Channels::Reconcile.call(server_configuration: config, bot: bot)
    ServerOnboarder.notify(bot, server, config)
    config
  end

  def channels(server)
    server.channels.map do |channel|
      {discord_id: channel.id, name: channel.name, channel_type: channel.type, overwrites: overwrites(channel)}
    end
  end

  def roles(server)
    server.roles.map { |role| {discord_id: role.id, name: role.name} }
  end

  def overwrites(channel)
    channel.permission_overwrites.values.map do |overwrite|
      {target_id: overwrite.id, target_type: overwrite.type.to_s, allow: overwrite.allow.bits, deny: overwrite.deny.bits}
    end
  end
end
