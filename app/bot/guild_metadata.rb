# frozen_string_literal: true

module GuildMetadata
  module_function

  def sync(server, bot)
    config = Ops::ServerConfiguration::Ensure.call(discord_id: server.id).value
    Ops::ServerConfiguration::Metadata::Sync.call(
      server_configuration: config,
      name: server.name,
      icon_hash: server.icon_id,
      member_count: server.member_count
    )
    Ops::ServerConfiguration::ServerChannels::Sync.call(server_configuration: config, channels: channels(server))
    Ops::ServerConfiguration::ServerRoles::Sync.call(
      server_configuration: config,
      roles: roles(server),
      bot_role_position: bot_role_position(server, bot)
    )
    Ops::ServerConfiguration::Channels::Reconcile.call(server_configuration: config, bot:)
    ServerOnboarder.notify(bot, server, config)
    config
  end

  def channels(server)
    server.channels.map do |channel|
      {
        discord_id: channel.id,
        name: channel.name,
        channel_type: channel.type,
        position: channel.position,
        parent_id: channel.parent_id,
        overwrites: overwrites(channel)
      }
    end
  end

  def roles(server)
    server.roles.map do |role|
      {discord_id: role.id, name: role.name, position: role.position, managed: role.managed?, color: role.color.combined, permissions: role.permissions.bits}
    end
  end

  def bot_role_position(server, bot)
    server.member(bot.profile.id).roles.map(&:position).max || 0
  end

  def overwrites(channel)
    channel.permission_overwrites.values.map do |overwrite|
      {target_id: overwrite.id, target_type: overwrite.type.to_s, allow: overwrite.allow.bits, deny: overwrite.deny.bits}
    end
  end
end
