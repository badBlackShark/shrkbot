class Shrkbot::PluginSelector
  include Discord::Plugin

  # guild => enabled plugins
  @@enabled = Hash(Discord::Snowflake, Array(String)).new

  # All the plugins that can be disabled.
  @@optional_plugins = [
    "logging",
    "roles",
  ]

  @first = true

  private def init_table
    Shrkbot.bot.db.create_table("shrk_plugins", ["guild int8", "plugins text[]"])
  end

  @[Discord::Handler(
    event: :guild_create
  )]
  def init(payload)
    if @first
      @first = false
      init_table
    end

    enabled = Shrkbot.bot.db.get_value("shrk_plugins", "plugins", "guild", payload.id, Array(String))
    if enabled
      @@enabled[payload.id] = enabled
    else
      # Not all plugins should be enabled by default
      @@enabled[payload.id] = ["logging"]
      Shrkbot.bot.db.insert_row("shrk_plugins", [payload.id, @@optional_plugins])

      msg = "Hi there, I'm shrkbot. You are receiving this message because either I'm seeing this server for the first time, or " \
            "my database was deleted. If you already know me, feel free to ignore this message.\n" \
            "I have enabled my logger by default, but all the other plugins that can be disabled are opt-in. " \
            "You can find out which modules can be enabled by using `.plugins`.\n" \
            "You can find out which commands are currently enabled with `.help`, and more about what they do with `.help [command]`. " \
            "This won't show disabled commands, and it won't show users commands they have too little permissions to use.\n" \
            "If there is no BotCommand role to distinguish staff members from regular ones, one will be created shortly. " \
            "In that case you will get another message.\n" \
            "If you have any questions, please message badBlackShark#6987." # Replace name when running this bot yourself.

      client.create_message(client.create_dm(payload.owner_id).id, msg)
    end
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new("disable"),
      GuildChecker.new,
      PermissionChecker.new(PermissionLevel::Moderator),
      ArgumentChecker.new(1),
    }
  )]
  def disable_plugin(payload, ctx)
    plugin = ctx[ArgumentChecker::Result].args.join(" ").downcase
    guild = ctx[GuildChecker::Result].id

    unless @@optional_plugins.includes?(plugin)
      client.create_message(payload.channel_id, "The plugin \"#{plugin}\" does either not exist or cannot be disabled. You can disable the following plugins: `#{@@enabled[guild].join("`, `")}`.")
      return
    end

    if @@enabled[guild].includes?(plugin)
      @@enabled[guild].delete(plugin)
      Shrkbot.bot.db.delete_row("shrk_plugins", "guild", guild)
      Shrkbot.bot.db.insert_row("shrk_plugins", [guild, @@enabled[guild]])
      client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
    else
      msg = client.create_message(payload.channel_id, "The plugin #{plugin} is already disabled.")
      sleep 5
      client.delete_message(payload.channel_id, msg.id)
      client.delete_message(payload.channel_id, payload.id)
    end
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new("enable"),
      GuildChecker.new,
      PermissionChecker.new(PermissionLevel::Moderator),
      ArgumentChecker.new(1),
    }
  )]
  def enable_plugin(payload, ctx)
    plugin = ctx[ArgumentChecker::Result].args.join(" ").downcase
    guild = ctx[GuildChecker::Result].id

    unless @@optional_plugins.includes?(plugin)
      client.create_message(payload.channel_id, "The plugin \"#{plugin}\" does either not exist or cannot be enabled. You can enable the following plugins: `#{(@@optional_plugins - @@enabled[guild]).join("`, `")}`.")
      return
    end

    if @@enabled[guild].includes?(plugin)
      msg = client.create_message(payload.channel_id, "The plugin #{plugin} is already enabled.")
      sleep 5
      client.delete_message(payload.channel_id, msg.id)
      client.delete_message(payload.channel_id, payload.id)
    else
      @@enabled[guild] << plugin
      Shrkbot.bot.db.delete_row("shrk_plugins", "guild", guild)
      Shrkbot.bot.db.insert_row("shrk_plugins", [guild, @@enabled[guild]])
      setup(plugin, guild, client)
      client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
    end
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new("plugins"),
      GuildChecker.new,
      PermissionChecker.new(PermissionLevel::Moderator),
    }
  )]
  def plugins(payload, ctx)
    client.create_message(payload.channel_id, "All the plugins you can toggle on or off:\n• #{@@optional_plugins.join("\n• ")}")
  end

  def setup(plugin : String, guild : Discord::Snowflake, client : Discord::Client)
    case plugin
    when "logging"
      Shrkbot::Logger.setup(guild, client)
    when "roles"
      Shrkbot::RoleAssignment.setup(guild, client)
    end
  end

  def self.enabled?(guild : Discord::Snowflake?, plugin : String)
    if guild
      # Plugins that cannot be disabled are always enabled.
      @@optional_plugins.includes?(plugin) ? @@enabled[guild].includes?(plugin) : true
    else
      # Everything is always enabled in DMs.
      true
    end
  end
end
