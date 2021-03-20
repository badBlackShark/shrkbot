class Shrkbot::RoleAssignment
  include Discord::Plugin

  # guild => channel
  @@role_channel = Hash(Discord::Snowflake, Discord::Snowflake).new
  # guild => assignable roles
  @@roles = Hash(Discord::Snowflake, Array(Discord::Role)).new
  # guild => role assignment message
  @@role_message = Hash(Discord::Snowflake, Discord::Snowflake).new
  # guild => bot sends DM to people assigning themselves a role
  @@role_notifs = Hash(Discord::Snowflake, Bool).new
  # guild => bot logs role assignment
  @@role_logs = Hash(Discord::Snowflake, Bool).new

  @first = true

  private def init_table
    Shrkbot.bot.db.create_table("shrk_roles", ["guild int8", "channel int8", "message int8", "roles int8[]", "role_notifs boolean", "role_logs boolean"])
  end

  @[Discord::Handler(
    event: :guild_create
  )]
  def init_roles(payload)
    spawn do
      # Make sure that the table exists on startup. Should only be relevant the very first time the bot
      # starts up. I tried to use ready for this, but apparently that was too slow and I got an exception.
      if @first
        init_table
        @first = false
      end

      Shrkbot::RoleAssignment.setup(payload.id, client) if PluginSelector.enabled?(payload.id, "roles")
    end
  end

  def self.setup(guild : Discord::Snowflake, client : Discord::Client)
    role_channel = Shrkbot.bot.db.get_value("shrk_roles", "channel", "guild", guild, Int64)

    if role_channel
      begin
        client.get_channel(role_channel.to_u64)
        @@role_channel[guild] = Discord::Snowflake.new(role_channel.to_u64)
      rescue e : Exception
        # The channel was deleted while the bot was offline.
      end
    else
      # This is a new server, so we need to create the database entry
      # We set the channel and message id to 0 for now, they'll be found later
      Shrkbot.bot.db.insert_row("shrk_roles", [guild, 0, 0, Array(Int64).new, true, true])
    end

    unless @@role_channel[guild]?
      role_channel = client.get_guild_channels(guild).find { |channel| channel.name =~ /roles|assign|rules/ }.try(&.id)
      if role_channel
        @@role_channel[guild] = role_channel
        Shrkbot.bot.db.update_value("shrk_roles", "channel", @@role_channel[guild], "guild", guild)
        client.create_message(@@role_channel[guild], "I have set this channel as my role assignment channel. Staff can disable role assignment with the `disable roles` command, or change the channel with `setRoleChannel`.")
      else
        @@role_channel[guild] = client.create_guild_channel(guild, "roles", Discord::ChannelType::GuildText, nil, nil, nil, nil, nil, nil, nil).id
        Shrkbot.bot.db.update_value("shrk_roles", "channel", @@role_channel[guild], "guild", guild)
        client.create_message(@@role_channel[guild], "I have created this channel as my role assignment channel. Staff can disable role assignment with the `disable roles` command, or change the channel with `setRoleChannel`.")
      end
    end

    all_roles = client.get_guild_roles(guild)
    role_ids = Shrkbot.bot.db.get_value("shrk_roles", "roles", "guild", guild, Array(Int64)).not_nil!
    @@roles[guild] = role_ids.map do |id|
      role = all_roles.find { |r| r.id == id.to_u64 }
      unless role
        # Role was deleted while the bot was offline, so we remove it from the database
        role_ids.delete(id)
        Shrkbot.bot.db.update_value("shrk_roles", "roles", role_ids, "guild", guild)
      end

      role
    end.compact.sort_by { |role| role.name }

    role_message = Shrkbot.bot.db.get_value("shrk_roles", "message", "guild", guild, Int64)

    begin
      # role_message will never be nil since we already create the row when it isn't present when looking for the channel
      @@role_message[guild] = client.get_channel_message(@@role_channel[guild], role_message.not_nil!.to_u64).id
    rescue e : Exception # The message was deleted while the bot was offline.
      @@role_message[guild] = create_role_message_and_reactions(guild, client)
      Shrkbot.bot.db.update_value("shrk_roles", "message", @@role_message[guild].to_u64.to_i64, "guild", guild)
    end

    # Like role_message, these will never be nil since we create the row if it doesn't exist above
    @@role_notifs[guild] = Shrkbot.bot.db.get_value("shrk_roles", "role_notifs", "guild", guild, Bool).not_nil!
    @@role_logs[guild] = Shrkbot.bot.db.get_value("shrk_roles", "role_logs", "guild", guild, Bool).not_nil!
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["roleLogsOff", "rl-"]),
      GuildChecker.new,
      EnabledChecker.new("roles"),
      PermissionChecker.new(PermissionLevel::Moderator),
    }
  )]
  def disable_logs(payload, ctx)
    guild_id = ctx[GuildChecker::Result].id

    @@role_logs[guild_id] = false
    Shrkbot.bot.db.update_value("shrk_roles", "role_logs", false, "guild", guild_id)
    client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["roleLogsOn", "rl+"]),
      GuildChecker.new,
      EnabledChecker.new("roles"),
      PermissionChecker.new(PermissionLevel::Moderator),
    }
  )]
  def enable_logs(payload, ctx)
    guild_id = ctx[GuildChecker::Result].id

    @@role_logs[guild_id] = true
    Shrkbot.bot.db.update_value("shrk_roles", "role_logs", true, "guild", guild_id)
    client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["roleNotifsOff", "rn-"]),
      GuildChecker.new,
      EnabledChecker.new("roles"),
      PermissionChecker.new(PermissionLevel::Moderator),
    }
  )]
  def disable_notifs(payload, ctx)
    guild_id = ctx[GuildChecker::Result].id

    @@role_notifs[guild_id] = false
    Shrkbot.bot.db.update_value("shrk_roles", "role_notifs", false, "guild", guild_id)
    client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["roleNotifsOn", "rn+"]),
      GuildChecker.new,
      EnabledChecker.new("roles"),
      PermissionChecker.new(PermissionLevel::Moderator),
    }
  )]
  def enable_notifs(payload, ctx)
    guild_id = ctx[GuildChecker::Result].id

    @@role_notifs[guild_id] = true
    Shrkbot.bot.db.update_value("shrk_roles", "role_notifs", true, "guild", guild_id)
    client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["setRoleChannel", "rc="]),
      GuildChecker.new,
      EnabledChecker.new("roles"),
      PermissionChecker.new(PermissionLevel::Moderator),
    }
  )]
  def set_role_channel(payload, ctx)
    channel = payload.content.match(/<#(\d*)>/)
    if channel
      guild = ctx[GuildChecker::Result].id
      id = Discord::Snowflake.new(channel[1])

      chnl = begin
        client.get_channel(id)
      rescue e : Exception
        client.create_message(payload.channel_id, "This channel doesn't seem to exist or isn't accessible to me.")
        return
      end

      if chnl.guild_id != guild
        client.create_message(payload.channel_id, "That channel is on a different guild.")
        return
      end

      begin
        client.delete_message(@@role_channel[guild], @@role_message[guild])
      rescue e : Exception
        # Message was deleted, no problem.
      end

      @@role_channel[guild] = id
      Shrkbot.bot.db.update_value("shrk_roles", "channel", id, "guild", guild)
      Logger.log(guild, "Set #{channel[0]} as the role assignment channel.", payload.author)
      client.create_reaction(payload.channel_id, payload.id, CHECKMARK)

      @@role_message[guild] = RoleAssignment.create_role_message_and_reactions(guild, client)
      Shrkbot.bot.db.update_value("shrk_roles", "message", @@role_message[guild].to_u64.to_i64, "guild", guild)
    else
      msg = client.create_message(payload.channel_id, "No channel was provided.")
      sleep 5
      client.delete_message(payload.channel_id, msg.id)
      client.delete_message(payload.channel_id, payload.id)
    end
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["addReactionRole", "rr+"]),
      GuildChecker.new,
      EnabledChecker.new("roles"),
      PermissionChecker.new(PermissionLevel::Moderator),
      ArgumentChecker.new(1),
    }
  )]
  def add_reaction_role(payload, ctx)
    guild = ctx[GuildChecker::Result].id
    role_name = ctx[ArgumentChecker::Result].args.join(" ")

    all_roles = client.get_guild_roles(guild)
    matcher = Utilities::FuzzyMatch.new(all_roles.map(&.name.downcase))
    match = matcher.find(role_name)

    unless match
      client.create_message(payload.channel_id, "Could not find any role with a name close to that.")
      return
    end

    # We can not nil this because we're finding the name by fuzzy matching over all the roles of the guild
    role = all_roles.find { |r| r.name.downcase == match }.not_nil!

    if @@roles[guild].map(&.id).includes?(role.id)
      client.create_message(payload.channel_id, "The role `#{role.name}` is already self-assignable.")
      return
    end

    @@roles[guild] << role
    Shrkbot.bot.db.update_value("shrk_roles", "roles", @@roles[guild].map(&.id.to_u64.to_i64), "guild", guild)
    client.delete_message(@@role_channel[guild], @@role_message[guild])

    client.create_message(payload.channel_id, "The role `#{role.name}` is now self-assignable.")

    @@role_message[guild] = Shrkbot::RoleAssignment.create_role_message_and_reactions(guild, client)
    Shrkbot.bot.db.update_value("shrk_roles", "message", @@role_message[guild].to_u64.to_i64, "guild", guild)
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["removeReactionRole", "rr-"]),
      GuildChecker.new,
      EnabledChecker.new("roles"),
      PermissionChecker.new(PermissionLevel::Moderator),
      ArgumentChecker.new(1),
    }
  )]
  def rem_reaction_role(payload, ctx)
    guild = ctx[GuildChecker::Result].id
    role_name = ctx[ArgumentChecker::Result].args.join(" ")

    all_roles = client.get_guild_roles(guild)
    matcher = Utilities::FuzzyMatch.new(all_roles.map(&.name.downcase))
    match = matcher.find(role_name)

    unless match
      client.create_message(payload.channel_id, "Could not find any role with a name close to that.")
      return
    end

    # We can not nil this because we're finding the name by fuzzy matching over all the roles of the guild
    role = all_roles.find { |r| r.name.downcase == match }.not_nil!

    unless @@roles[guild].map(&.id).includes?(role.id)
      client.create_message(payload.channel_id, "The role `#{role.name}` isn't currently self-assignable.")
      return
    end

    @@roles[guild].delete(@@roles[guild].find { |r| r.id == role.id })
    Shrkbot.bot.db.update_value("shrk_roles", "roles", @@roles[guild].map(&.id.to_u64.to_i64), "guild", guild)
    client.delete_message(@@role_channel[guild], @@role_message[guild])

    client.create_message(payload.channel_id, "The role `#{role.name}` is no longer self-assignable.")

    @@role_message[guild] = Shrkbot::RoleAssignment.create_role_message_and_reactions(guild, client)
    Shrkbot.bot.db.update_value("shrk_roles", "message", @@role_message[guild].to_u64.to_i64, "guild", guild)
  end

  @[Discord::Handler(
    event: :message_reaction_add
  )]
  def add_role_on_reaction_add(payload)
    guild_id = payload.guild_id
    return unless PluginSelector.enabled?(guild_id, "roles")
    return unless guild_id && payload.message_id == @@role_message[guild_id]?
    idx = index_from_emoji(payload.emoji.name)
    return if idx == -1 || idx >= @@roles[guild_id].size

    role = @@roles[guild_id][idx]
    if client.get_guild_member(guild_id, payload.user_id).roles.find { |r| r == role.id }
      return
    end
    client.add_guild_member_role(guild_id, payload.user_id, role.id)

    if @@role_notifs[guild_id]
      client.create_message(client.create_dm(payload.user_id).id, "I gave you the role `#{role.name}` on \"#{Shrkbot.bot.cache.resolve_guild(guild_id).name}\".")
    end
    if @@role_logs[guild_id]
      member = client.get_guild_member(guild_id, payload.user_id)
      Logger.log(guild_id, "#{(member.nick || member.user.username)}##{member.user.discriminator} gave themselves the role `#{role.name}`.")
    end
  end

  @[Discord::Handler(
    event: :message_reaction_remove
  )]
  def add_role_on_reaction_remove(payload)
    guild_id = payload.guild_id
    return unless PluginSelector.enabled?(guild_id, "roles")
    return unless guild_id && payload.message_id == @@role_message[guild_id]?
    idx = index_from_emoji(payload.emoji.name)
    return if idx == -1 || idx >= @@roles[guild_id].size

    role = @@roles[guild_id][idx]
    unless client.get_guild_member(guild_id, payload.user_id).roles.find { |r| r == role.id }
      return
    end
    # For some reason as of now this doesn't take Snowflakes
    client.remove_guild_member_role(guild_id.to_u64, payload.user_id.to_u64, role.id.to_u64)

    if @@role_notifs[guild_id]
      client.create_message(client.create_dm(payload.user_id).id, "I removed the role `#{role.name}` on \"#{Shrkbot.bot.cache.resolve_guild(guild_id).name}\".")
    end
    if @@role_logs[guild_id]
      member = client.get_guild_member(guild_id, payload.user_id)
      Logger.log(guild_id, "#{(member.nick || member.user.username)}##{member.user.discriminator} unassigned themselves the role `#{role.name}`.")
    end
  end

  @[Discord::Handler(
    event: :message_reaction_add
  )]
  def refresh_role_message_on_refresh_reaction(payload)
    guild_id = payload.guild_id
    return unless PluginSelector.enabled?(guild_id, "roles")
    return unless guild_id && payload.message_id == @@role_message[guild_id]?
    return unless Permissions.permission_level(payload.user_id, guild_id) >= PermissionLevel::Moderator
    return unless payload.emoji.name == "🔄"

    client.delete_message(@@role_channel[guild_id], @@role_message[guild_id])
    @@role_message[guild_id] = Shrkbot::RoleAssignment.create_role_message_and_reactions(guild_id, client)
    Shrkbot.bot.db.update_value("shrk_roles", "message", @@role_message[guild_id].to_u64.to_i64, "guild", guild_id)
  end

  protected def self.create_role_message_and_reactions(guild : Discord::Snowflake, client : Discord::Client) : Discord::Snowflake
    msg = client.create_message(@@role_channel[guild], "", Shrkbot::RoleMessage.to_embed(@@roles[guild]))
    emoji = "a"
    @@roles[guild].each do |_r|
      client.create_reaction(@@role_channel[guild], msg.id, Utilities::Emojis.name_to_unicode(emoji))
      emoji = emoji.succ
    end
    client.create_reaction(@@role_channel[guild], msg.id, Utilities::Emojis.name_to_unicode("refresh"))

    return msg.id
  end

  # If the reaction is a letter emoji, this turns it in an index to find the appropriate role with
  private def index_from_emoji(emoji : String)
    str = "a"
    0.upto(25) do |i|
      return i if Utilities::Emojis.name_to_emoji(str) == emoji
      str = str.succ
    end

    return -1
  end
end
