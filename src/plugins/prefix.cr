class Shrkbot::Prefix
  include Discord::Plugin

  @@prefixes = Hash(Discord::Snowflake, String).new

  @first = true

  private def init_table
    Shrkbot.bot.db.create_table("shrk_prefixes", ["id int8", "prefix varchar(20)"])
  end

  @[Discord::Handler(
    event: :guild_create
  )]
  def init_prefix(payload)
    if @first
      @first = false
      init_table
    end
    @@prefixes[payload.id] = Shrkbot.bot.db.get_value("shrk_prefixes", "prefix", "id", payload.id, String) || "."
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      SetPrefixCommand.new([".setPrefix", ".pfx="]),
      GuildChecker.new,
      PermissionChecker.new(PermissionLevel::Moderator),
      ArgumentChecker.new(1),
    }
  )]
  def set_prefix(payload, ctx)
    guild = ctx[GuildChecker::Result].id
    prefix = ctx[ArgumentChecker::Result].args.first

    # We don't want any spaces in our prefix, because of the way e.g. the argument checker works.
    if prefix.includes?(" ")
      msg = client.create_message(payload.channel_id, "The prefix must not contain spaces!")
      sleep 5
      client.delete_message(payload.channel_id, msg.id)
      client.delete_message(payload.channel_id, payload.id)
      return
    end

    Shrkbot.bot.db.delete_row("shrk_prefixes", "id", guild)
    Shrkbot.bot.db.insert_row("shrk_prefixes", [guild, prefix])

    @@prefixes[guild] = prefix

    Logger.log(guild, "The prefix for this server has been changed to `#{prefix}`.", payload.author)
    client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: SetPrefixCommand.new(".prefix")
  )]
  def prefix(payload, ctx)
    guild = client.cache.try &.resolve_channel(payload.channel_id).guild_id
    client.create_message(payload.channel_id, "The current prefix is `#{Prefix.get_prefix(guild)}`.")
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      SetPrefixCommand.new([".resetPrefix", ".pfx!"]),
      GuildChecker.new,
      PermissionChecker.new(PermissionLevel::Moderator),
    }
  )]
  def reset_prefix(payload, ctx)
    guild = ctx[GuildChecker::Result].id
    Shrkbot.bot.db.delete_row("shrk_prefixes", "id", guild)
    @@prefixes.delete(guild)

    Logger.log(guild, "The prefix for this server has been reset to `.`.", payload.author)
    client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
  end

  def self.get_prefix(guild : Discord::Snowflake?)
    @@prefixes[guild]? || "."
  end
end
