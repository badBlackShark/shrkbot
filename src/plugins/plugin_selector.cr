class Shrkbot::PluginSelector
  include Discord::Plugin

  # guild => enabled plugins
  @@enabled = Hash(Discord::Snowflake, Array(String)).new

  # All the plugins that can be disabled.
  @@optional_plugins = [
    "logging",
    "roles",
    "mutes",
    "reminders",
    "welcomes",
    "auto-removal",
    "halts",
    "news",
  ]

  @first = true

  private def init_table
    Shrkbot.bot.db.create_table("shrk_plugins", ["guild int8", "plugins text[]"])
  end

  @[Discord::Handler(
    event: :guild_create
  )]
  def init(payload)
    spawn do
      if @first
        @first = false
        init_table
      end

      enabled = Shrkbot.bot.db.get_value("shrk_plugins", "plugins", "guild", payload.id, Array(String))
      if enabled
        @@enabled[payload.id] = enabled
      else
        # Only logging should be enabled by default
        @@enabled[payload.id] = ["logging"]
        Shrkbot.bot.db.insert_row("shrk_plugins", [payload.id, @@enabled[payload.id]])

        msg = "Hi there, I'm shrkbot. You are receiving this message because either I'm seeing this server for the first time, or " \
              "my database was deleted. If you already know me, feel free to ignore this message.\n" \
              "I have enabled my logger by default, but all the other plugins that can be disabled are opt-in. " \
              "It is highly recommended not to turn off logging. It occasionally contains important information. " \
              "You can find out which modules can be enabled by using `.plugins`.\n" \
              "You can find out which commands are currently enabled with `.help`, and more about what they do with `.help [command]`. " \
              "This won't show disabled commands, and it won't show users commands they have insufficient permissions to use.\n" \
              "If there is no BotCommand role to distinguish staff members from regular ones, one will be created shortly. " \
              "In that case you will get another message.\n" \
              "If you have any questions, please message badBlackShark#6987." # Replace name when running this bot yourself.

        client.create_message(client.create_dm(payload.owner_id).id, msg)
      end
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

    # TODO: Make this fuzzy matched
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

    # TODO: Make this fuzzy matched
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
    when "mutes"
      Shrkbot::Mutes.setup(guild, client)
    when "welcomes"
      Shrkbot::JoinLeave.setup(guild, client)
    when "auto-removal"
      Shrkbot::AutoRemoval.setup(guild, client)
    when "halts"
      Shrkbot::HaltNotifs.setup(guild, client)
    when "news"
      Shrkbot::NewsNotifs.setup(guild, client)
    end
  end

  def self.enabled?(guild : Discord::Snowflake?, plugin : String)
    if guild
      # Plugins that cannot be disabled are always enabled.
      if @@optional_plugins.includes?(plugin)
        while @@enabled[guild]?.nil?
          # We've hit a race condition, so we're waiting for the PluginSelector to initialize this guild
          # This can happen when other plugins try to initialize on GuildCreate before this one does.
          # Because of this we use concurrency in all of the initial setup calls that get triggered
          # by a GuildCreate. Probably not the cleanest way, but it works :)
          sleep 1
        end
        @@enabled[guild].includes?(plugin)
      else
        true
      end
    else
      # Everything is always enabled in DMs.
      true
    end
  end

  def self.guilds_with_plugin(plugin : String)
    return @@enabled.select { |guild, plugins| plugins.includes?(plugin) }.keys
  end
end
