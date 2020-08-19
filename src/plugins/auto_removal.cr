class Shrkbot::AutoRemoval
  include Discord::Plugin

  # guild => banned phrases
  @@banned_phrases = Hash(Discord::Snowflake, Array(String)).new
  # guild => phrases that'll get deleted, but only warn the user
  @@soft_banned_phrases = Hash(Discord::Snowflake, Array(String)).new
  # guild => active warns for users that will be muted on the next offense
  @@warned_users = Hash(Discord::Snowflake, Array(Warn)).new
  # guild => time for warns (changing this will not affect old warns)
  @@warn_duration = Hash(Discord::Snowflake, Time::Span).new
  # guild => time for mutes (changing this will not affect old mutes)
  @@mute_duration = Hash(Discord::Snowflake, Time::Span).new
  # guild => whether whitespaces should be ignored for banned phrases
  @@ignore_whitespace = Hash(Discord::Snowflake, Bool).new
  # guild => users that are allowed to use banned phrases - e.g. to post prohibited links
  @@permitted_users = Hash(Discord::Snowflake, Array(Discord::Snowflake)).new

  @first = true

  @[Discord::Handler(
    event: :guild_create
  )]
  def init_removal(payload)
    spawn do
      if @first
        @first = false
        Shrkbot.bot.db.create_table(
          "shrk_autoremove",
          [
            "guild int8",
            "banned text[]",
            "softbanned text[]",
            "warnduration varchar(20)",
            "muteduration varchar(20)",
            "ignore_whitespace boolean",
          ]
        )

        Shrkbot.bot.db.create_table("shrk_warned_users", ["guild int8", "user_id int8", "time timestamptz", "phrase text"])
      end

      AutoRemoval.setup(payload.id, client) if PluginSelector.enabled?(payload.id, "auto-removal")
    end
  end

  def self.setup(guild : Discord::Snowflake, client : Discord::Client)
    time_raw = Shrkbot.bot.db.get_value("shrk_autoremove", "warnduration", "guild", guild, String)
    unless time_raw
      # This is a new guild for this plugin, so we create a database entry
      Shrkbot.bot.db.insert_row("shrk_autoremove", [guild, Array(String).new, Array(String).new, "1w", "1d", false])
      msg = "Auto-removal has been enabled. " \
            "The default warn period was set to 1 week. Staff can change it with `setWarnDuration <duration>`. " \
            "The default mute period was set to 1 day. Staff can change it with `setMuteDuration <duration>`. " \
            "By default whitespace isn't ignored when scanning for banned phrases. Staff can change this with " \
            "`ignoreWhitespaceOn`.\n" \
            "I will log the banned phrases people use in my log channel. For this reason, " \
            "I would recommend only making it readable for staff members."
      Logger.log(guild, msg)
      time_raw = "1w"
    end
    @@warn_duration[guild] = convert_string_to_timespan(time_raw)

    # We can not_nil! these since we either find the row, or create a new one with default values above
    time_raw = Shrkbot.bot.db.get_value("shrk_autoremove", "muteduration", "guild", guild, String).not_nil!
    @@mute_duration[guild] = convert_string_to_timespan(time_raw)
    @@ignore_whitespace[guild] = Shrkbot.bot.db.get_value("shrk_autoremove", "ignore_whitespace", "guild", guild, Bool).not_nil!
    @@banned_phrases[guild] = Shrkbot.bot.db.get_value("shrk_autoremove", "banned", "guild", guild, Array(String)).not_nil!
    @@soft_banned_phrases[guild] = Shrkbot.bot.db.get_value("shrk_autoremove", "softbanned", "guild", guild, Array(String)).not_nil!

    @@warned_users[guild] = Array(Warn).new
    @@permitted_users[guild] = Array(Discord::Snowflake).new

    rs = Shrkbot.bot.db.get_rows("shrk_warned_users", "guild", guild)
    rs.each do
      guild_id = Discord::Snowflake.new(rs.read(Int64).to_u64)
      user_id = Discord::Snowflake.new(rs.read(Int64).to_u64)
      time = rs.read(Time)
      phrase = rs.read(String)

      schedule_unwarn(time, user_id, guild_id, client, phrase, true)
    end
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      GuildChecker.new(silent: true),
      EnabledChecker.new("auto-removal"),
    }
  )]
  def message_scanner(payload, ctx)
    guild_id = ctx[GuildChecker::Result].id
    return if payload.author.id == client.client_id
    return if Permissions.permission_level(payload.author.id, guild_id) >= PermissionLevel::Moderator

    if phrase = AutoRemoval.contains_banned_phrase(payload.content.downcase, guild_id, soft: false)
      if @@permitted_users[guild_id].includes?(payload.author.id)
        client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
        return
      end
      client.delete_message(payload.channel_id, payload.id)
      Mutes.schedule_unmute(
        @@mute_duration[guild_id].from_now,
        guild_id,
        payload.author.id,
        "Use of banned phrase: *#{phrase.gsub("\\s*", "")}*.",
        client,
        Shrkbot.bot.cache.resolve_current_user
      )
      # If an already warned user posts a hard-banned phrase, we want to refresh the warn.
      if warn = @@warned_users[guild_id].find { |warn| warn.user == payload.author.id }
        time = @@warn_duration[guild_id].from_now
        new_warn = AutoRemoval.schedule_unwarn(time, payload.author.id, guild_id, client, phrase, true)
        Shrkbot.bot.db.insert_row("shrk_warned_users", [guild_id, payload.author.id, time, phrase])
        member = Shrkbot.bot.cache.resolve_member(guild_id, payload.author.id)
        name = "*#{member.user.username}##{member.user.discriminator}*"
        name += " [aka *#{member.nick}*]" if member.nick
        Logger.log(guild_id, "⚠️ #{name} was already warned. Their warn has been extended until #{new_warn.time.to_s(TIME_FORMAT)}.")
      end
    elsif phrase = AutoRemoval.contains_banned_phrase(payload.content.downcase, guild_id, soft: true)
      if @@permitted_users[guild_id].includes?(payload.author.id)
        client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
        return
      end
      client.delete_message(payload.channel_id, payload.id)
      if warn = @@warned_users[guild_id].find { |warn| warn.user == payload.author.id }
        warn.cancel
        @@warned_users[guild_id].delete(warn)
        Mutes.schedule_unmute(
          @@mute_duration[guild_id].from_now,
          guild_id,
          payload.author.id,
          "Use of soft-banned phrase while already warned: *#{phrase.gsub("\\s*", "")}*.",
          client,
          Shrkbot.bot.cache.resolve_current_user
        )
      else
        time = @@warn_duration[guild_id].from_now
        warn = AutoRemoval.schedule_unwarn(time, payload.author.id, guild_id, client, phrase)
        Shrkbot.bot.db.insert_row("shrk_warned_users", [guild_id, payload.author.id, time, phrase])
        member = Shrkbot.bot.cache.resolve_member(guild_id, payload.author.id)
        name = "*#{member.user.username}##{member.user.discriminator}*"
        name += " [aka *#{member.nick}*]" if member.nick
        Logger.log(guild_id, "⚠️ #{name} has been warned until #{warn.time.to_s(TIME_FORMAT)}. Reason: Use of soft-banned phrase: *#{phrase.gsub("\\s*", "")}*.")
      end
    end
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["bannedPhrases", "prohibited?"]),
      GuildChecker.new,
      EnabledChecker.new("auto-removal"),
    }
  )]
  def banned_phrases(payload, ctx)
    guild_id = ctx[GuildChecker::Result].id
    if Permissions.permission_level(payload.author.id, guild_id) == PermissionLevel::User
      msg = "In everyone's interest I only post the banned phrases for staff users. " \
            "If you want to know exactly what you can't say, please ask a member of the server staff " \
            "to run this command for you, or to send you a screenshot of the list."
      client.create_message(payload.channel_id, msg)
    else
      if @@banned_phrases[guild_id].empty? && @@soft_banned_phrases[guild_id].empty?
        client.create_message(payload.channel_id, "There's no banned phrases for this guild.")
      else
        embed = Discord::Embed.new
        embed.title = "All the banned phrases for this guild."

        fields = Array(Discord::EmbedField).new
        fields << Discord::EmbedField.new(
          name: "Banned phrases",
          value: @@banned_phrases[guild_id].map { |phrase| "• #{phrase.gsub("\\s*", "")}" }.join("\n")
        ) unless @@banned_phrases[guild_id].empty?
        fields << Discord::EmbedField.new(
          name: "Soft-banned phrases",
          value: @@soft_banned_phrases[guild_id].map { |phrase| "• #{phrase.gsub("\\s*", "")}" }.join("\n")
        ) unless @@soft_banned_phrases[guild_id].empty?
        embed.fields = fields

        embed.footer = Discord::EmbedFooter.new(text: "For soft-banned phrases you get a warning first, and a mute on the second offense.")

        client.create_message(payload.channel_id, "", embed)
      end
    end
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["warnedUsers", "warns?"]),
      GuildChecker.new,
      EnabledChecker.new("auto-removal"),
      PermissionChecker.new(PermissionLevel::Moderator),
    }
  )]
  def warned_users(payload, ctx)
    guild_id = ctx[GuildChecker::Result].id
    if (warns = @@warned_users[guild_id]).empty?
      client.create_message(payload.channel_id, "No one is warned on this guild at the moment.")
    else
      embed = Discord::Embed.new
      embed.title = "All currently warned users."
      embed.fields = warns.map do |warn|
        member = Shrkbot.bot.cache.resolve_member(guild_id, warn.user)
        name = "*#{member.user.username}##{member.user.discriminator}*"
        name += " [aka *#{member.nick}*]" if member.nick

        value = "Warned until #{warn.time.to_s(TIME_FORMAT)} for using a soft-banned phrase: *#{warn.phrase}*."

        Discord::EmbedField.new(name: name, value: value)
      end

      embed.colour = 0x38AFE5

      client.create_message(payload.channel_id, "", embed)
    end
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["unwarn", "warn-"]),
      GuildChecker.new,
      EnabledChecker.new("auto-removal"),
      PermissionChecker.new(PermissionLevel::Moderator),
      ArgumentChecker.new(1),
    }
  )]
  def unwarn(payload, ctx)
    if payload.mentions.empty?
      client.create_message(payload.channel_id, "You need to mention at least one user.")
      return
    end

    guild_id = ctx[GuildChecker::Result].id

    payload.mentions.each do |user|
      warn = @@warned_users[guild_id].find { |warn| warn.user == user.id }
      unless warn
        client.create_message(payload.channel_id, "#{user.username}##{user.discriminator} isn't currently warned.")
        next
      end

      warn.cancel
      @@warned_users[guild_id].delete(warn)
      Shrkbot.bot.db.delete_row_double_filter("shrk_warned_users", "guild", guild_id, "user_id", user.id)

      member = Shrkbot.bot.cache.resolve_member(guild_id, payload.author.id)
      name = "*#{member.user.username}##{member.user.discriminator}*"
      name += " [aka *#{member.nick}*]" if member.nick
      Logger.log(guild_id, "#{name} has been unwarned.", payload.author)
    end

    client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new("permit"),
      GuildChecker.new,
      EnabledChecker.new("auto-removal"),
      PermissionChecker.new(PermissionLevel::Moderator),
      ArgumentChecker.new(1),
    }
  )]
  def permit(payload, ctx)
    if payload.mentions.empty?
      client.create_message(payload.channel_id, "You need to mention a user.")
      return
    end

    guild_id = ctx[GuildChecker::Result].id

    user = payload.mentions.first
    @@permitted_users[guild_id] << user.id

    msg = "#{user.mention} is exempt from auto-deletion for 1 minute. I will react with ✅ on all messages that were approved this way."
    confirm = client.create_message(payload.channel_id, msg)

    Tasker.in(1.minutes) do
      @@permitted_users[guild_id].delete(user.id)
      message = client.create_message(payload.channel_id, "#{user.mention} is no longer exempt from auto-deletion.")
    end

    client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["setAutoMuteDuration", "muteTime="]),
      GuildChecker.new,
      EnabledChecker.new("auto-removal"),
      PermissionChecker.new(PermissionLevel::Moderator),
      ArgumentChecker.new(1, 1),
    }
  )]
  def set_auto_mute_duration(payload, ctx)
    time_raw = ctx[ArgumentChecker::Result].args.find { |a| a =~ /^((\d+)[smhdw]{1})+$/i }

    unless time_raw
      client.create_message(payload.channel_id, "No valid time was provided. Use the help command if you're not sure of the correct format.")
      return
    end

    guild_id = ctx[GuildChecker::Result].id
    @@mute_duration[guild_id] = AutoRemoval.convert_string_to_timespan(time_raw)
    Shrkbot.bot.db.update_value("shrk_autoremove", "muteduration", time_raw, "guild", guild_id)

    client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["autoMuteDuration", "muteTime?"]),
      GuildChecker.new,
      EnabledChecker.new("auto-removal"),
      PermissionChecker.new(PermissionLevel::Moderator),
    }
  )]
  def auto_mute_duration(payload, ctx)
    time = AutoRemoval.convert_timespan_to_string(@@mute_duration[payload.guild_id])
    client.create_message(payload.channel_id, "Users posting banned phrases will get muted for #{time}.")
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["setAutoWarnDuration", "warnTime="]),
      GuildChecker.new,
      EnabledChecker.new("auto-removal"),
      PermissionChecker.new(PermissionLevel::Moderator),
      ArgumentChecker.new(1, 1),
    }
  )]
  def set_auto_warn_duration(payload, ctx)
    time_raw = ctx[ArgumentChecker::Result].args.find { |a| a =~ /^((\d+)[smhdw]{1})+$/i }

    unless time_raw
      client.create_message(payload.channel_id, "No valid time was provided. Use the help command if you're not sure of the correct format.")
      return
    end

    guild_id = ctx[GuildChecker::Result].id
    @@warn_duration[guild_id] = AutoRemoval.convert_string_to_timespan(time_raw)
    Shrkbot.bot.db.update_value("shrk_autoremove", "warnduration", time_raw, "guild", guild_id)

    client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["autoWarnDuration", "warnTime?"]),
      GuildChecker.new,
      EnabledChecker.new("auto-removal"),
      PermissionChecker.new(PermissionLevel::Moderator),
    }
  )]
  def auto_warn_duration(payload, ctx)
    time = AutoRemoval.convert_timespan_to_string(@@warn_duration[payload.guild_id])
    client.create_message(payload.channel_id, "The warning for users posting a soft-banned phrase will last #{time}.")
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["addBannedPhrase", "rmv+"]),
      GuildChecker.new,
      EnabledChecker.new("auto-removal"),
      PermissionChecker.new(PermissionLevel::Moderator),
      ArgumentChecker.new(1),
    }
  )]
  def add_banned_phrase(payload, ctx)
    guild_id = ctx[GuildChecker::Result].id
    args = ctx[ArgumentChecker::Result].args
    phrase = args.reject { |arg| arg.downcase == "-warn" }.join(" ").downcase
    hard = args.find { |arg| arg.downcase == "-warn" }.nil?

    # We do this instead of just doing @@banned_phrases[guild].includes?(phrase) because of
    # subphrases. E.g. if "foo" is already banned, banning "foo bar" doesn't do anything new.
    if AutoRemoval.contains_banned_phrase(phrase, guild_id, soft: false) || AutoRemoval.contains_banned_phrase(phrase, guild_id, soft: true)
      client.create_message(payload.channel_id, "This phrase (or a subphrase of it) is already banned.")
      return
    end
    phrase = phrase.split("").join("\\s*") if @@ignore_whitespace[guild_id]

    if hard
      @@banned_phrases[guild_id] << phrase
      Shrkbot.bot.db.update_value("shrk_autoremove", "banned", @@banned_phrases[guild_id], "guild", guild_id)

      client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
      client.create_reaction(payload.channel_id, payload.id, Utilities::Emojis.name_to_unicode("ban"))
    else
      @@soft_banned_phrases[guild_id] << phrase
      Shrkbot.bot.db.update_value("shrk_autoremove", "softbanned", @@soft_banned_phrases[guild_id], "guild", guild_id)
      client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
      client.create_reaction(payload.channel_id, payload.id, Utilities::Emojis.name_to_unicode("warn"))
    end
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["removeBannedPhrase", "rmv-"]),
      GuildChecker.new,
      EnabledChecker.new("auto-removal"),
      PermissionChecker.new(PermissionLevel::Moderator),
      ArgumentChecker.new(1),
    }
  )]
  def remove_banned_phrase(payload, ctx)
    guild_id = ctx[GuildChecker::Result].id
    phrase = ctx[ArgumentChecker::Result].args.join(" ").downcase

    unless AutoRemoval.contains_banned_phrase(phrase, guild_id, soft: false) || AutoRemoval.contains_banned_phrase(phrase, guild_id, soft: true)
      client.create_message(payload.channel_id, "This phrase isn't currently banned.")
      return
    end
    phrase = phrase.split("").join("\\s*") if @@ignore_whitespace[guild_id]

    @@banned_phrases[guild_id].delete(phrase)
    Shrkbot.bot.db.update_value("shrk_autoremove", "banned", @@banned_phrases[guild_id], "guild", guild_id)
    @@soft_banned_phrases[guild_id].delete(phrase)
    Shrkbot.bot.db.update_value("shrk_autoremove", "softbanned", @@soft_banned_phrases[guild_id], "guild", guild_id)
    client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["ignoreWhitespaceOn", "noSpaceOn"]),
      GuildChecker.new,
      EnabledChecker.new("auto-removal"),
      PermissionChecker.new(PermissionLevel::Moderator),
    }
  )]
  def ignore_whitespace_on(payload, ctx)
    guild_id = ctx[GuildChecker::Result].id
    if @@ignore_whitespace[guild_id]
      client.create_message(payload.channel_id, "Whitespace is already being ignored.")
    else
      @@ignore_whitespace[guild_id] = true
      Shrkbot.bot.db.update_value("shrk_autoremove", "ignore_whitespace", true, "guild", guild_id)
      @@banned_phrases[guild_id].map! { |phrase| phrase.split("").join("\\s*") }
      Shrkbot.bot.db.update_value("shrk_autoremove", "banned", @@banned_phrases[guild_id], "guild", guild_id)
      @@soft_banned_phrases[guild_id].map! { |phrase| phrase.split("").join("\\s*") }
      Shrkbot.bot.db.update_value("shrk_autoremove", "softbanned", @@soft_banned_phrases[guild_id], "guild", guild_id)
      client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
    end
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["ignoreWhitespaceOff", "noSpaceOff"]),
      GuildChecker.new,
      EnabledChecker.new("auto-removal"),
      PermissionChecker.new(PermissionLevel::Moderator),
    }
  )]
  def ignore_whitespace_off(payload, ctx)
    guild_id = ctx[GuildChecker::Result].id
    if @@ignore_whitespace[guild_id]
      @@ignore_whitespace[guild_id] = false
      Shrkbot.bot.db.update_value("shrk_autoremove", "ignore_whitespace", false, "guild", guild_id)
      @@banned_phrases[guild_id].map! { |phrase| phrase.gsub("\\s*", "") }
      Shrkbot.bot.db.update_value("shrk_autoremove", "banned", @@banned_phrases[guild_id], "guild", guild_id)
      @@soft_banned_phrases[guild_id].map! { |phrase| phrase.gsub("\\s*", "") }
      Shrkbot.bot.db.update_value("shrk_autoremove", "softbanned", @@soft_banned_phrases[guild_id], "guild", guild_id)
      client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
    else
      client.create_message(payload.channel_id, "Whitespace is already being considered.")
    end
  end

  def self.contains_banned_phrase(content : String, guild : Discord::Snowflake, soft : Bool)
    phrases = soft ? @@soft_banned_phrases[guild] : @@banned_phrases[guild]

    phrases.each do |phrase|
      if @@ignore_whitespace[guild]
        return phrase if content =~ Regex.new(phrase)
      else
        return phrase if content.includes?(phrase)
      end
    end

    return nil
  end

  def self.schedule_unwarn(time : Time, user : Discord::Snowflake, guild : Discord::Snowflake, client : Discord::Client, phrase : String, silent : Bool = false)
    # If there's a previous warn and the user gets a new one we override the previous one.
    # This only happens if an already warned user posts a hard-banned phrase.
    if prev_warn = @@warned_users[guild].find { |warn| warn.user == user }
      prev_warn.cancel
      @@warned_users[guild].delete(prev_warn)
      Shrkbot.bot.db.delete_row_double_filter("shrk_warned_users", "guild", guild, "user_id", user)
    end

    job = Tasker.at(time) do
      client.create_message(client.create_dm(user).id, "You're no longer warned in #{Shrkbot.bot.cache.resolve_guild(guild).name}.")
      warn = @@warned_users[guild].find { |warn| warn.user == user }
      @@warned_users[guild].delete(warn)
      Shrkbot.bot.db.delete_row_double_filter("shrk_warned_users", "guild", guild, "user_id", user)
      nil
    end

    warn = Warn.new(job, time, user, guild, phrase)
    @@warned_users[guild] << warn

    unless silent
      msg = "You've been warned until #{time.to_s(TIME_FORMAT)} in #{Shrkbot.bot.cache.resolve_guild(guild).name} " \
            "for using a soft-banned phrase: *#{phrase.gsub("\\s*", "")}*."
      client.create_message(client.create_dm(user).id, msg)
    end

    return warn
  end

  def self.convert_string_to_timespan(time_raw : String) : Time::Span
    matchdata = time_raw.scan(/\d+[smhdw]{1}/i)
    timespan = Time::Span.new
    matchdata.each do |match|
      raw = match[0]
      amount = raw[0..-2].to_i
      increment = raw[-1].to_s

      case increment
      when "w"
        timespan += amount.days * 7
      when "d"
        timespan += amount.days
      when "h"
        timespan += amount.hours
      when "m"
        timespan += amount.minutes
      when "s"
        timespan += amount.seconds
      end
    end

    return timespan
  end

  def self.convert_timespan_to_string(timespan : Time::Span) : String
    return String.build do |str|
      if timespan.days == 1
        str << "#{timespan.days} day, "
      elsif timespan.days > 1
        str << "#{timespan.days} days, "
      end
      if timespan.hours == 1
        str << "#{timespan.hours} hour, "
      elsif timespan.hours > 1
        str << "#{timespan.hours} hours, "
      end
      if timespan.minutes == 1
        str << "#{timespan.minutes} minute, "
      elsif timespan.minutes > 1
        str << "#{timespan.minutes} minutes, "
      end
      if timespan.seconds == 1
        str << "#{timespan.seconds} second, "
      elsif timespan.seconds > 1
        str << "#{timespan.seconds} seconds, "
      end
      str.back(2)
    end
  end
end
