class Shrkbot::Reminders
  include Discord::Plugin

  @@reminders = Hash(Discord::Snowflake, Array(Reminder)).new

  @first = true

  @[Discord::Handler(
    event: :guild_create
  )]
  def init_reminders(payload)
    spawn do
      # Make sure that the table exists on startup. Should only be relevant the very first time the bot
      # starts up. I tried to use ready for this, but apparently that was too slow and I got an exception.
      if @first
        @first = false
        Shrkbot.bot.db.create_table("shrk_reminders", ["channel int8", "user_id int8", "time timestamptz", "created_at timestamptz", "message text", "id int4", "dm boolean", "guild int8"])
        rs = Shrkbot.bot.db.get_table("shrk_reminders")

        rs.each do
          channel = Discord::Snowflake.new(rs.read(Int64).to_u64)
          user = Discord::Snowflake.new(rs.read(Int64).to_u64)
          time = rs.read(Time)
          created_at = rs.read(Time)
          message = rs.read(String)
          id = rs.read(Int32)
          dm = rs.read(Bool)
          guild = rs.read(Int64?)
          guild = Discord::Snowflake.new(guild.to_u64) if guild

          @@reminders[user] = Array(Reminder).new unless @@reminders[user]?
          Reminders.schedule_reminder(time, created_at, channel, user, message, id, dm, guild, client)
        end
      end
    end
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["remind", "rmd"]),
      EnabledChecker.new("reminders"),
      ArgumentChecker.new(2),
    }
  )]
  def remind(payload, ctx)
    args = ctx[ArgumentChecker::Result].args

    time_raw = args.find { |a| a =~ /^((\d+)[smhdw]{1})+$/i }
    unless time_raw
      client.create_message(payload.channel_id, "No time was provided. Use the help command if you're not sure of the correct format.")
      return
    end

    dm = !(args.find { |a| a.downcase == "-dm" }.nil?)

    msg = args.reject { |a| a == time_raw || a.downcase == "-dm" }.join(" ")
    if msg.empty?
      client.create_message(payload.channel_id, "Please tell me what to remind you of.")
      return
    end
    # Sanitize the message a little. First escape all unescaped mass pings
    msg = msg.gsub(/(?<!`)(@everyone|@here)(?!.*`)/, "`\\1`")
    # Next, replace all role pings with their name
    msg = msg.gsub(/<@&(\d+)>/) { |m| "`@#{Shrkbot.bot.cache.resolve_role(Discord::Snowflake.new($1)).name}`" }

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

    unless @@reminders[payload.author.id]?
      @@reminders[payload.author.id] = Array(Reminder).new
    end

    id = (@@reminders[payload.author.id].max_of? { |reminder| reminder.id } || 0) + 1

    created_at = Time.local
    time = timespan.from_now
    reminder = Reminders.schedule_reminder(time, created_at, payload.channel_id, payload.author.id, msg, id, dm, payload.guild_id, client)

    Shrkbot.bot.db.insert_row(
      "shrk_reminders",
      [
        reminder.channel,
        reminder.user,
        reminder.time,
        reminder.created_at,
        reminder.message,
        reminder.id,
        reminder.dm,
        reminder.guild,
      ]
    )

    confirmation = "Created reminder for #{time.to_s(TIME_FORMAT)} with message \"#{msg}\" and id **#{id}.**"
    confirmation += " You will be reminded of this in a direct message." if dm
    client.create_message(payload.channel_id, confirmation)
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["reminders", "rmd?"]),
      EnabledChecker.new("reminders"),
      ArgumentChecker.new(0, 1),
    }
  )]
  def reminders(payload, ctx)
    args = ctx[ArgumentChecker::Result].args

    all = payload.guild_id.nil?
    all ||= args.first.downcase.includes?("all") unless args.empty?

    reminders = @@reminders[payload.author.id]?

    if reminders && !reminders.empty?
      reminders = reminders.reject { |reminder| reminder.dm || reminder.guild != payload.guild_id } unless all
      if reminders.empty?
        client.create_message(payload.channel_id, "You currently don't have any active reminders in this guild. Use this command with the `all` flag to see all of your reminders.")
      else
        embed = Discord::Embed.new
        embed.title = "Reminders for #{payload.author.username}##{payload.author.discriminator}"
        embed.description = all ? "Showing all of your reminders." : "Only showing reminders for this guild."
        embed.footer = Discord::EmbedFooter.new(text: "Use the \"all\" flag to see all of your reminders.") unless all
        embed.colour = 0x38AFE5

        fields = Array(Discord::EmbedField).new
        reminders.each do |reminder|
          field = reminder.to_embed_field
          if all
            if (guild = reminder.guild) && !reminder.dm
              field.name += " (on #{Shrkbot.bot.cache.resolve_guild(guild).name})"
            else
              field.name += " (as a direct message)"
            end
          end
          fields << field
        end

        embed.fields = fields

        client.create_message(payload.channel_id, "", embed)
      end
    else
      client.create_message(payload.channel_id, "You currently do not have any active reminders.")
    end
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["unremind", "rmd-"]),
      EnabledChecker.new("reminders"),
      ArgumentChecker.new(1),
    }
  )]
  def unremind(payload, ctx)
    id = ctx[ArgumentChecker::Result].args.first.to_i?

    unless id
      client.create_message(payload.channel_id, "Please provide a numerical ID.")
      return
    end

    reminders = @@reminders[payload.author.id]?
    unless reminders && !reminders.empty?
      client.create_message(payload.channel_id, "You currently do not have any active reminders.")
      return
    end

    reminder = reminders.find { |rmd| rmd.id == id }
    unless reminder
      valid_ids = reminders.map { |rmd| rmd.id }
      client.create_message(payload.channel_id, "I couldn't find a reminder for you with that ID. Valid IDs are: #{valid_ids.join(", ")}.")
      return
    end

    reminder.cancel
    Shrkbot.bot.db.delete_row_double_filter("shrk_reminders", "user_id", payload.author.id, "id", id)
    @@reminders[payload.author.id].delete(reminder)

    client.create_message(payload.channel_id, "You will no longer be reminded about \"#{reminder.message}\" on #{reminder.time.to_s(TIME_FORMAT)}.")
  end

  def self.schedule_reminder(time : Time,
                             created_at : Time,
                             channel : Discord::Snowflake,
                             user : Discord::Snowflake,
                             msg : String,
                             id : Int32,
                             dm : Bool,
                             guild : Discord::Snowflake?,
                             client : Discord::Client)
    job = Tasker.at(time) do
      elapsed = time - created_at
      time_string = String.build do |str|
        str << "approximately "
        if elapsed.days == 1
          str << "#{elapsed.days} day, "
        elsif elapsed.days > 1
          str << "#{elapsed.days} days, "
        end
        if elapsed.hours == 1
          str << "#{elapsed.hours} hour, "
        elsif elapsed.hours > 1
          str << "#{elapsed.hours} hours, "
        end
        if elapsed.minutes == 1
          str << "#{elapsed.minutes} minute, "
        elsif elapsed.minutes > 1
          str << "#{elapsed.minutes} minutes, "
        end
        if elapsed.seconds == 1
          str << "#{elapsed.seconds} second, "
        elsif elapsed.seconds > 1
          str << "#{elapsed.seconds} seconds, "
        end
        str.back(2)
        str << " ago"
      end

      # We delete these first in case something goes wrong with sending the reminder - e.g.
      # if the channel the reminder is supposed to be sent to gets deleted, or the bot is removed
      # from the guild. Otherwise, the failing reminder will be re-scheduled, just to re-fail,
      # every time the bot restarts.
      Shrkbot.bot.db.delete_row_double_filter("shrk_reminders", "user_id", user, "id", id)
      @@reminders[user].delete(@@reminders[user].find { |reminder| reminder.id == id })

      send_to = dm ? client.create_dm(user).id : channel
      message = "<@#{user}>, #{time_string} you asked to be reminded of this: \"#{msg}\""

      begin
        client.create_message(send_to, message)
      rescue e : Exception
        client.create_message(channel, message += "\n\nI tried to DM you this reminder, but you don't allow DMs from me.")
      end

      nil
    end

    reminder = Reminder.new(job, time, created_at, channel, user, msg, id, dm, guild)
    @@reminders[user] << reminder

    return reminder
  end
end
