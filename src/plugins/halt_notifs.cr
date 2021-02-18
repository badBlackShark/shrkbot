require "rss"
require "myhtml"

class Shrkbot::HaltNotifs
  include Discord::Plugin

  # guild => channel
  @@notif_channel = Hash(Discord::Snowflake, Discord::Snowflake).new
  @@halts = Array(Halt).new
  @@schedule : Tasker::Repeat(Array(Halt))?

  @first = true

  @[Discord::Handler(
    event: :guild_create
  )]
  def init_halts(payload)
    spawn do
      if @first
        @first = false
        Shrkbot.bot.db.create_table("shrk_halts", ["guild int8", "channel int8"])
      end

      HaltNotifs.setup(payload.id, client) if PluginSelector.enabled?(payload.id, "halts")
    end
  end

  def self.setup(guild : Discord::Snowflake, client : Discord::Client)
    notif_channel = Shrkbot.bot.db.get_value("shrk_halts", "channel", "guild", guild, Int64)

    if notif_channel
      begin
        client.get_channel(notif_channel.to_u64)
        @@notif_channel[guild] = Discord::Snowflake.new(notif_channel.to_u64)
      rescue e : Exception
        # The channel was deleted while the bot was offline.
      end
    else
      # This is a new server, so we need to create the database entry
      # We set the channel to 0 for now, it'll be found later
      Shrkbot.bot.db.insert_row("shrk_halts", [guild, 0])
    end

    unless @@notif_channel[guild]?
      notif_channel = client.get_guild_channels(guild).find { |channel| channel.name =~ /welcome|general|lobby/ }.try(&.id)
      if notif_channel
        @@notif_channel[guild] = notif_channel
        Shrkbot.bot.db.update_value("shrk_halts", "channel", @@notif_channel[guild], "guild", guild)
        client.create_message(@@notif_channel[guild], "I have set this channel as my channel for halt notifications. Staff can disable these with the `disable halts` command, or change the channel with `setHaltChannel`.")
      else
        @@notif_channel[guild] = client.create_guild_channel(guild, "halts", Discord::ChannelType::GuildText, nil, nil, nil, nil, nil, nil, nil).id
        Shrkbot.bot.db.update_value("shrk_halts", "channel", @@notif_channel[guild], "guild", guild)
        client.create_message(@@notif_channel[guild], "I have created this channel as my channel for halt notifications. Staff can disable these with the `disable halts` command, or change the channel with `setHaltChannel`.")
      end
    end

    feed = RSS.parse("http://www.nasdaqtrader.com/rss.aspx?feed=tradehalts")
    @@halts = feed.items.map { |item| parse_halt(item.description) }
    start_request_loop(client) unless @@schedule
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["setHaltChannel", "hc="]),
      GuildChecker.new,
      EnabledChecker.new("halts"),
      PermissionChecker.new(PermissionLevel::Moderator),
    }
  )]
  def set_halt_channel(payload, ctx)
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

      @@notif_channel[guild] = id

      Shrkbot.bot.db.update_value("shrk_halts", "channel", @@notif_channel[guild], "guild", guild)

      Logger.log(guild, "Set #{channel[0]} as the channel for halt notifications.", payload.author)
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
      Command.new(["stopcode", "sc?"]),
      EnabledChecker.new("halts"),
      ArgumentChecker.new(1)
    }
  )]
  def stopcode(payload, ctx)
    code = ctx[ArgumentChecker::Result].args.first

    client.create_message(payload.channel_id, "", CodeList.find_code(code).to_embed)
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["lastHalt"]),
      EnabledChecker.new("halts")
    }
  )]
  def last_halt(payload, ctx)
    client.create_message(payload.channel_id, "This is the most recent halt update that I know of:", @@halts.first.to_embed)
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new(["halts"]),
      EnabledChecker.new("halts"),
      ArgumentChecker.new(0,1)
    }
  )]
  def halts(payload, ctx)
    args = ctx[ArgumentChecker::Result].args
    if args.empty?
      total_parts = (@@halts.size / 10).ceil.to_i
      i = 1
      @@halts.each_slice(10) do |halts|
        embed = Discord::Embed.new

        embed.title = "Every current trading halt. Part #{i}/#{total_parts}"
        embed.fields = halts.map(&.to_embed_field)
        embed.colour = 0x38AFE5
        embed.footer = Discord::EmbedFooter.new(text: "All times are in Eastern Time. All dates are in MM/DD/YYYY.")

        client.create_message(payload.channel_id, "", embed)

        i += 1
      end
    else
      ticker = args.first
      halts = @@halts.select { |halt| halt.ticker.downcase == ticker.downcase }

      if halts.empty?
        client.create_message(payload.channel_id, "There are no current trading halts for $#{ticker.upcase}.")
      else
        embed = Discord::Embed.new

        embed.title = "Current trading halts for #{halts.first.name}"
        embed.fields = halts.map(&.to_embed_field)
        embed.colour = 0x38AFE5
        embed.footer = Discord::EmbedFooter.new(text: "All times are in Eastern Time. All dates are in MM/DD/YYYY.")

        client.create_message(payload.channel_id, "", embed)
      end
    end
  end

  private def self.start_request_loop(client : Discord::Client)
    @@schedule = Tasker.every(1.minute) do
      feed = RSS.parse("http://www.nasdaqtrader.com/rss.aspx?feed=tradehalts")
      halts = feed.items.map { |item| parse_halt(item.description) }

      new_halts = halts.reject { |halt| @@halts.includes?(halt) }
      new_halts.each do |halt|
        halt_nr = @@halts.select { |h| h.ticker == halt.ticker && !h.res_trade_time.empty? }.size + 1
        halt.halt_nr = halt_nr
        PluginSelector.guilds_with_plugin("halts").each do |guild|
          spawn do
            client.create_message(@@notif_channel[guild], "", halt.to_embed)
          end
        end
      end

      @@halts = halts
    end
  end

  private def self.parse_halt(raw_html : String)
    parser = Myhtml::Parser.new(raw_html)

    date, time, ticker, name, market, stopcode, pausprice, res_date, res_quote_time, res_trade_time = parser.nodes(:td).map(&.inner_text.strip).to_a

    return Halt.new(date, time, ticker, name, market, stopcode, pausprice, res_date, res_quote_time, res_trade_time)
  end
end
