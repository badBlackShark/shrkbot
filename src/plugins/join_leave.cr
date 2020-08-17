class Shrkbot::JoinLeave
  include Discord::Plugin

  # guild => message
  @@join_message = Hash(Discord::Snowflake, String).new
  @@leave_message = Hash(Discord::Snowflake, String).new
  # guild => channel
  @@welcome_channel = Hash(Discord::Snowflake, Discord::Snowflake).new

  @first = true

  @[Discord::Handler(
    event: :guild_create
  )]
  def init_join_leave(payload)
    spawn do
      # Make sure that the table exists on startup. Should only be relevant the very first time the bot
      # starts up. I tried to use ready for this, but apparently that was too slow and I got an exception.
      if @first
        Shrkbot.bot.db.create_table("shrk_join_leave", ["guild int8", "channel int8", "join_msg text", "leave_msg text"])
        @first = false
      end

      Shrkbot::JoinLeave.setup(payload.id, client) if PluginSelector.enabled?(payload.id, "welcomes")
    end
  end

  def self.setup(guild : Discord::Snowflake, client : Discord::Client)
    welcome_channel = Shrkbot.bot.db.get_value("shrk_join_leave", "channel", "guild", guild, Int64)

    if welcome_channel
      begin
        client.get_channel(welcome_channel.to_u64)
        @@welcome_channel[guild] = Discord::Snowflake.new(welcome_channel.to_u64)
      rescue e : Exception
        # The channel was deleted while the bot was offline.
      end
    else
      # This is a new server, so we need to create the database entry
      # We set the channel to 0 for now, it'll be found later
      Shrkbot.bot.db.insert_row("shrk_join_leave", [guild, 0, "", ""])
    end

    unless @@welcome_channel[guild]?
      welcome_channel = client.get_guild_channels(guild).find { |channel| channel.name =~ /welcome|general|lobby/ }.try(&.id)
      if welcome_channel
        @@welcome_channel[guild] = welcome_channel
        Shrkbot.bot.db.update_value("shrk_join_leave", "channel", @@welcome_channel[guild], "guild", guild)
        client.create_message(@@welcome_channel[guild], "I have set this channel as my channel for join and leave messages. Staff can disable these with the `disable welcomes` command, or change the channel with `setWelcomeChannel`.")
      else
        @@welcome_channel[guild] = client.create_guild_channel(guild, "welcome", Discord::ChannelType::GuildText, nil, nil, nil, nil, nil, nil, nil).id
        Shrkbot.bot.db.update_value("shrk_join_leave", "channel", @@welcome_channel[guild], "guild", guild)
        client.create_message(@@welcome_channel[guild], "I have created this channel as my channel for join and leave messages. Staff can disable these with the `disable welcomes` command, or change the channel with `setWelcomeChannel`.")
      end
    end

    # We can not_nil! these since we create the table with both being empty Strings, so we're always fine.
    @@join_message[guild] = Shrkbot.bot.db.get_value("shrk_join_leave", "join_msg", "guild", guild, String).not_nil!
    @@leave_message[guild] = Shrkbot.bot.db.get_value("shrk_join_leave", "leave_msg", "guild", guild, String).not_nil!
  end

  @[Discord::Handler(
    event: :guild_member_add
  )]
  def join(payload)
    return unless PluginSelector.enabled?(payload.guild_id, "welcomes")
    msg = @@join_message[payload.guild_id]
    return if msg.empty?

    msg = msg.gsub("{user}", payload.user.mention)
    client.create_message(@@welcome_channel[payload.guild_id], msg)
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["setJoinMessage", "jm="]),
      GuildChecker.new,
      EnabledChecker.new("welcomes"),
      PermissionChecker.new(PermissionLevel::Moderator),
      ArgumentChecker.new(0),
    }
  )]
  def set_join_message(payload, ctx)
    guild_id = ctx[GuildChecker::Result].id
    if (args = ctx[ArgumentChecker::Result].args).empty?
      @@join_message[guild_id] = ""
      Shrkbot.bot.db.update_value("shrk_join_leave", "join_msg", "", "guild", guild_id)
      client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
      msg = client.create_message(payload.channel_id, "You set an empty join message, so I will no longer send a message when new users join.")
      sleep 5
      client.delete_message(payload.channel_id, msg.id)
    else
      msg = args.join(" ")
      @@join_message[guild_id] = msg
      Shrkbot.bot.db.update_value("shrk_join_leave", "join_msg", msg, "guild", guild_id)
      client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
    end
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["joinMessage", "jm?"]),
      GuildChecker.new,
      EnabledChecker.new("welcomes"),
      PermissionChecker.new(PermissionLevel::Moderator),
    }
  )]
  def join_message(payload, ctx)
    guild_id = ctx[GuildChecker::Result].id
    msg = @@join_message[guild_id]

    if msg.empty?
      client.create_message(payload.channel_id, "Join messages are currently disabled. Set one using `setJoinMessage [message]`.")
    else
      client.create_message(payload.channel_id, "This message will be displayed in <##{@@welcome_channel[guild_id]}> when new users join: \"#{msg}\"")
    end
  end

  @[Discord::Handler(
    event: :guild_member_remove
  )]
  def leave(payload)
    return unless PluginSelector.enabled?(payload.guild_id, "welcomes")
    msg = @@leave_message[payload.guild_id]
    return if msg.empty?

    msg = msg.gsub("{user}", "#{payload.user.username}##{payload.user.discriminator}")
    client.create_message(@@welcome_channel[payload.guild_id], msg)
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["setLeaveMessage", "lm="]),
      GuildChecker.new,
      EnabledChecker.new("welcomes"),
      PermissionChecker.new(PermissionLevel::Moderator),
      ArgumentChecker.new(0),
    }
  )]
  def set_leave_message(payload, ctx)
    guild_id = ctx[GuildChecker::Result].id
    if (args = ctx[ArgumentChecker::Result].args).empty?
      @@leave_message[guild_id] = ""
      Shrkbot.bot.db.update_value("shrk_join_leave", "leave_msg", "", "guild", guild_id)
      client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
      msg = client.create_message(payload.channel_id, "You set an empty leave message, so I will no longer send a message when users leave.")
      sleep 5
      client.delete_message(payload.channel_id, msg.id)
    else
      msg = args.join(" ")
      @@leave_message[guild_id] = msg
      Shrkbot.bot.db.update_value("shrk_join_leave", "leave_msg", msg, "guild", guild_id)
      client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
    end
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["leaveMessage", "lm?"]),
      GuildChecker.new,
      EnabledChecker.new("welcomes"),
      PermissionChecker.new(PermissionLevel::Moderator),
    }
  )]
  def leave_message(payload, ctx)
    guild_id = ctx[GuildChecker::Result].id
    msg = @@leave_message[guild_id]

    if msg.empty?
      client.create_message(payload.channel_id, "Leave messages are currently disabled. Set one using `setLeaveMessage [message]`.")
    else
      client.create_message(payload.channel_id, "This message will be displayed in <##{@@welcome_channel[guild_id]}> when users leave: \"#{msg}\"")
    end
  end
end
