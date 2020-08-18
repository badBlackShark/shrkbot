class Shrkbot::Mutes
  include Discord::Plugin

  # guild => { user =>  Mute}
  @@mutes = Hash(Discord::Snowflake, Hash(Discord::Snowflake, Mute)).new

  class_getter! muted_role : Hash(Discord::Snowflake, Discord::Role)
  @@denied : Discord::Permissions = Discord::Permissions.flags(SendMessages, Speak, AddReactions)
  @first = true

  @[Discord::Handler(
    event: :guild_create
  )]
  def init_mutes(payload)
    spawn do
      # Make sure that the table exists on startup. Should only be relevant the very first time the bot
      # starts up. I tried to use ready for this, but apparently that was too slow and I got an exception.
      if @first
        Shrkbot.bot.db.create_table("shrk_mutes", ["guild int8", "user_id int8", "time timestamptz", "reason text"])
        @@muted_role = Hash(Discord::Snowflake, Discord::Role).new
        @first = false
      end

      Shrkbot::Mutes.setup(payload.id, client) if PluginSelector.enabled?(payload.id, "mutes")
    end
  end

  def self.setup(guild_id : Discord::Snowflake, client : Discord::Client)
    @@mutes[guild_id] = Hash(Discord::Snowflake, Mute).new
    guild = Shrkbot.bot.cache.resolve_guild(guild_id)

    role = client.get_guild_roles(guild.id).find { |role| role.name.downcase == "muted" }
    if role
      Mutes.muted_role[guild_id] = role
    else
      Mutes.muted_role[guild_id] = create_muted_role(guild.id, client)

      msg = "I have created a role called `muted` and a channel overwrite for it on every channel. " \
            "It will be assigned to members you or the bot mutes, and will disallow them to chat in text " \
            "channels, speak in voice channels, or add reactions. If something happens to it, use the " \
            "`refreshMutedRole` and I will set it up again :)"
      client.create_message(client.create_dm(guild.owner_id).id, msg)
    end
    rs = Shrkbot.bot.db.get_rows("shrk_mutes", "guild", guild.id)

    rs.each do
      guild_id = Discord::Snowflake.new(rs.read(Int64).to_u64)
      user_id = Discord::Snowflake.new(rs.read(Int64).to_u64)
      time = rs.read(Time)
      message = rs.read(String)

      schedule_unmute(time, guild_id, user_id, message, client, nil, true)
    end
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["mutes", "!?"]),
      GuildChecker.new,
      EnabledChecker.new("mutes"),
      PermissionChecker.new(PermissionLevel::Moderator),
    }
  )]
  def list_mutes(payload, ctx)
    guild_id = ctx[GuildChecker::Result].id

    mutes = @@mutes[guild_id]
    if mutes.empty?
      client.create_message(payload.channel_id, "No one's currently muted on this guild.")
    else
      embed = Discord::Embed.new
      embed.title = "Everyone currently muted on this server."
      embed.description = String.build do |str|
        mutes.each do |user_id, mute|
          member = client.get_guild_member(guild_id, user_id)
          str << "• #{Mutes.member_format(member)}, muted until #{mute.time.to_s(TIME_FORMAT)}. Reason: #{mute.message}\n\n"
        end
      end
      embed.colour = 0x38AFE5

      client.create_message(payload.channel_id, "", embed)
    end
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["mute", "!"]),
      GuildChecker.new,
      EnabledChecker.new("mutes"),
      PermissionChecker.new(PermissionLevel::Moderator),
      ArgumentChecker.new(2),
    }
  )]
  def mute(payload, ctx)
    guild_id = ctx[GuildChecker::Result].id
    args = ctx[ArgumentChecker::Result].args

    time_raw = args.find { |a| a =~ /^((\d+)[smhdw]{1})+$/i }
    users = payload.mentions
    reason = args.reject { |a| a =~ /<@!?(\d+)>/ || a =~ /^((\d+)[smhdw]{1})+$/i }.join(" ")
    reason = "*No reason provided.*" if reason.empty?

    if users.empty?
      client.create_message(payload.channel_id, "You need to mention at least one user to be muted.")
      return
    end

    unless time_raw
      client.create_message(payload.channel_id, "No time was provided. Use the help command if you're not sure of the correct format.")
      return
    end

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

    users.each do |user|
      client.add_guild_member_role(guild_id, user.id, Mutes.muted_role[guild_id].id)
      time = timespan.from_now
      mute = Mutes.schedule_unmute(time, guild_id, user.id, reason, client, payload.author)
      if mute.time != time
        # This triggers if the new mute lasts shorter than the old mute.
        member = client.get_guild_member(guild_id, user.id)
        msg = "#{Mutes.member_format(member)} is already muted until #{time.to_s(TIME_FORMAT)}. Reason: \"#{mute.message}\""
        client.create_message(payload.channel_id, msg)
        client.create_reaction(payload.channel_id, payload.id, CROSSMARK)
      else
        Shrkbot.bot.db.insert_row("shrk_mutes", [guild_id, user.id, time, reason])
        client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
      end
    end
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["unmute", "!-"]),
      GuildChecker.new,
      EnabledChecker.new("mutes"),
      PermissionChecker.new(PermissionLevel::Moderator),
      ArgumentChecker.new(1),
    }
  )]
  def unmute(payload, ctx)
    guild_id = ctx[GuildChecker::Result].id

    payload.mentions.each do |user|
      member = client.get_guild_member(guild_id, user.id)
      unless @@mutes[guild_id][user.id]?
        client.create_message(payload.channel_id, "#{Mutes.member_format(member)} isn't currently muted.")
        next
      end

      @@mutes[guild_id][user.id].cancel
      Mutes.delete_mute(guild_id, user.id, client)
      Logger.log(guild_id, "#{Mutes.member_format(member)} was unmuted.", payload.author)
      client.create_reaction(payload.channel_id, payload.id, CHECKMARK)
    end
  end

  def self.schedule_unmute(time : Time,
                           guild : Discord::Snowflake,
                           user : Discord::Snowflake,
                           message : String,
                           client : Discord::Client,
                           mod : Discord::User?,
                           silent_mute : Bool? = false,
                           silent_unmute : Bool? = false)
    if @@mutes[guild]? && @@mutes[guild][user]?
      return @@mutes[guild][user] if @@mutes[guild][user].time > time

      @@mutes[guild][user].cancel
      Shrkbot.bot.db.delete_row_double_filter("shrk_mutes", "guild", guild, "user_id", user)
    end
    job = Tasker.at(time) do
      delete_mute(guild, user, client)

      unless silent_unmute
        # We fetch member here and below in case the nickname changed in the meantime
        member = client.get_guild_member(guild, user)
        Logger.log(guild, "#{member_format(member)} is no longer muted. Mute reason: #{message}")
      end

      client.create_message(client.create_dm(user).id, "You're no longer muted for `#{message}` in *#{Shrkbot.bot.cache.resolve_guild(guild).name}*.")
      nil
    end

    mute = Mute.new(job, time, guild, user, message)
    @@mutes[guild][user] = mute

    member = client.get_guild_member(guild, user)
    unless silent_mute
      Logger.log(guild, "Muted #{member_format(member)} until #{time.to_s(TIME_FORMAT)}. Reason: #{message}", mod)
      client.create_message(client.create_dm(user).id, "You've been muted until #{time.to_s(TIME_FORMAT)}. Reason: #{message}")
    end

    return mute
  end

  def self.delete_mute(guild : Discord::Snowflake, user : Discord::Snowflake, client : Discord::Client)
    client.remove_guild_member_role(guild.to_u64, user.to_u64, Mutes.muted_role[guild].id.to_u64)
    @@mutes[guild].delete(user)
    Shrkbot.bot.db.delete_row_double_filter("shrk_mutes", "guild", guild, "user_id", user)
  end

  def self.member_format(member : Discord::GuildMember)
    str = "*#{member.user.username}##{member.user.discriminator}*"
    str += " [aka *#{member.nick}*]" if member.nick

    return str
  end

  private def self.create_muted_role(guild_id : Discord::Snowflake, client : Discord::Client)
    role = client.create_guild_role(guild_id, "muted")
    client.get_guild_channels(guild_id).each do |channel|
      client.edit_channel_permissions(
        channel.id,
        role.id,
        "role",
        Discord::Permissions::None,
        @@denied
      )
    end

    return role
  end
end
