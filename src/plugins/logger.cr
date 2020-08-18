class Shrkbot::Logger
  include Discord::Plugin

  # guild => channel
  @@log_channel = Hash(Discord::Snowflake, Discord::Snowflake).new

  @first = true

  private def init_table
    Shrkbot.bot.db.create_table("shrk_logger", ["guild int8", "channel int8"])
  end

  @[Discord::Handler(
    event: :guild_create
  )]
  def init_log_channel(payload)
    spawn do
      # Make sure that the table exists on startup. Should only be relevant the very first time the bot
      # starts up. I tried to use ready for this, but apparently that was too slow and I got an exception.
      if @first
        init_table
        @first = false
      end

      Shrkbot::Logger.setup(payload.id, client) if PluginSelector.enabled?(payload.id, "logger")
    end
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["setLogChannel", "lc="]),
      GuildChecker.new,
      EnabledChecker.new("logging"),
      PermissionChecker.new(PermissionLevel::Moderator),
    }
  )]
  def set_log_channel(payload, ctx)
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

      @@log_channel[guild] = id

      Shrkbot.bot.db.delete_row("shrk_logger", "guild", guild)
      Shrkbot.bot.db.insert_row("shrk_logger", [guild, id])

      Logger.log(guild, "This channel has been set as the log channel.", payload.author)
      client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
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
      Command.new("logChannel"),
      EnabledChecker.new("logging"),
      GuildChecker.new,
    }
  )]
  def log_channel(payload, ctx)
    client.create_message(payload.channel_id, "This server's log channel is <##{@@log_channel[ctx[GuildChecker::Result].id]}>.")
  end

  def self.setup(guild : Discord::Snowflake, client : Discord::Client)
    log_channel = Shrkbot.bot.db.get_value("shrk_logger", "channel", "guild", guild, Int64)

    if log_channel
      begin
        client.get_channel(log_channel.to_u64)
        @@log_channel[guild] = Discord::Snowflake.new(log_channel.to_u64)
      rescue e : Exception
        # The channel was deleted while the bot was offline.
        Shrkbot.bot.db.delete_row("shrk_logger", "guild", guild)
      end
    end

    unless @@log_channel[guild]?
      log_channel = client.get_guild_channels(guild).find { |channel| channel.name =~ /log|mod|staff/ }.try(&.id)
      if log_channel
        @@log_channel[guild] = log_channel
        Shrkbot.bot.db.insert_row("shrk_logger", [guild, @@log_channel[guild]])
        client.create_message(@@log_channel[guild], "I have set this channel as my log channel. Staff can disable logging with the `disable logging` command, or change the channel with `setLogChannel`.")
      else
        @@log_channel[guild] = client.create_guild_channel(guild, "logs", Discord::ChannelType::GuildText, nil, nil, nil, nil, nil, nil, nil).id
        Shrkbot.bot.db.insert_row("shrk_logger", [guild, @@log_channel[guild]])
        client.create_message(@@log_channel[guild], "I have created this channel as my log channel. Staff can disable logging with the `disable logging` command, or change the channel with `setLogChannel`.")
      end
    end
  end

  def self.log(guild_id : Discord::Snowflake, message : String, mod : Discord::User? = nil)
    if PluginSelector.enabled?(guild_id, "logging")
      message += "\nThis action was performed by `#{mod.username}##{mod.discriminator}`." if mod
      Shrkbot.bot(guild_id.to_u64).client.create_message(@@log_channel[guild_id], message)
    end
  end
end
