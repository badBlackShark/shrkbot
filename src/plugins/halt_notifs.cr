require "rss"
require "myhtml"

class Shrkbot::HaltNotifs
  include Discord::Plugin

  # guild => channel
  @@notif_channel = Hash(Discord::Snowflake, Discord::Snowflake).new
  @@halts = Array(Halt).new
  @@schedule : Tasker::Repeat(Nil)?

  class_getter! api : YahooFinance::Api

  @first = true

  @[Discord::Handler(
    event: :guild_create
  )]
  def init_halts(payload)
    spawn do
      if @first
        @first = false
        Shrkbot.bot.db.create_table("shrk_halts", ["guild int8", "channel int8"])
        @@api = YahooFinance::Api.new(Shrkbot.config.yahoo_token)
        feed = RSS.parse("http://www.nasdaqtrader.com/rss.aspx?feed=tradehalts")
        @@halts = feed.items.map { |item| HaltNotifs.parse_halt(item.description) }
        HaltNotifs.start_request_loop(Shrkbot.bot.client)
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
        # @@notif_channel[guild] = client.create_guild_channel(guild, "halts", Discord::ChannelType::GuildText, nil, nil, nil, nil, nil, nil, nil).id
        Shrkbot.bot.db.update_value("shrk_halts", "channel", @@notif_channel[guild], "guild", guild)
        client.create_message(@@notif_channel[guild], "I have created this channel as my channel for halt notifications. Staff can disable these with the `disable halts` command, or change the channel with `setHaltChannel`.")
      end
    end
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
      ArgumentChecker.new(1),
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
      EnabledChecker.new("halts"),
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
      ArgumentChecker.new(0, 1),
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

  def self.start_request_loop(client : Discord::Client)
    i = 1
    @@schedule = Tasker.every(1.minute) do
      feed = RSS.parse("http://www.nasdaqtrader.com/rss.aspx?feed=tradehalts")
      halts = feed.items.map { |item| parse_halt(item.description) }

      new_halts = halts.reject { |halt| @@halts.includes?(halt) }

      new_halts.each do |halt|
        if halt.res_trade_time.empty?
          halt_nr = @@halts.select { |h| h.ticker == halt.ticker && !h.res_trade_time.empty? }.size + 1
          halt.halt_nr = halt_nr
          price_action = get_price_action(halt.ticker)
          if price_action[0] == "error"
            halt.price_action_error = "Price action could not be displayed due to an error on Yahoo Finance's side. Error: #{price_action[1]}"
          else
            halt_price, last_close, today_open, last_candle_open, pm_open, pm_close, halt_direction = price_action
            halt.set_price_action(halt_price, last_close, today_open, last_candle_open, pm_open, pm_close, halt_direction)
          end
        else
          old_halt = @@halts.find { |h| h.ticker == halt.ticker && h.res_trade_time.empty? }
          if old_halt
            halt.set_price_action_by_other(old_halt)
            halt.resume_price = get_resume_price(halt.ticker)
            @@halts.delete(old_halt)
          else
            halt.price_action_error = "Resume time set without previous known halt. Price action cannot be displayed."
          end
        end

        # Every 15th halt notification we want to inclue our donation message.
        if i == 15
          i = 1
          halt.donation_msg = true
        end

        embed = halt.to_embed
        PluginSelector.guilds_with_plugin("halts").each do |guild|
          spawn do
            client.create_message(@@notif_channel[guild], "", embed)
          end
        end

        @@halts << halt
        i += 1
      end

      # Clears the the internal list when the online list resets
      if halts.size < @@halts.size
        @@halts = halts
      end

      # The garbage collector doesn't seem to do its job without this. I really dislike using this,
      # but memory increases monotonically without this. My feeling is that the old space for
      # @@halts doesn't get cleared as it should. Either way, this is the solution until I find a
      # better one.
      GC.collect
    end
  end

  private def self.get_resume_price(symbol : String)
    raw = HaltNotifs.api.get_chart(symbol)["chart"]
    if raw["result"].as_a?
      # This is not fully guaranteed to get the resume price. I think this becomes inaccurate
      # if between the resume happening and the bot picking it up Yahoo starts a new candle interval.
      # Making sure this doesn't happen does more work than it helps right now though.
      return raw["result"][0]["indicators"]["quote"][0]["open"].as_a.last.as_f
    else
      return -1.0
    end
  end

  private def self.get_price_action(symbol : String)
    begin
      raw = HaltNotifs.api.get_chart(symbol)["chart"]
    rescue e : Exception
      return ["error", e.message.not_nil!]
    end
    if raw["result"].as_a?
      chart_data = raw["result"][0]
      quote_data = chart_data["indicators"]["quote"][0]
      meta_data = raw["result"][0]["meta"]

      halt_price = meta_data["regularMarketPrice"]?.try(&.as_f?)
      last_close = meta_data["previousClose"]?.try(&.as_f?)

      if quote_data.size == 0
        return [halt_price, last_close, nil, nil, nil, nil, "intederminable"]
      else
        time = meta_data["currentTradingPeriod"]["regular"]["start"].as_i
        index = chart_data["timestamp"].as_a.index { |timestamp| timestamp.as_i >= time } if chart_data["timestamp"]?
        today_open = if index
          quote_data["open"][index].as_f?
        else
          -1
        end

        last_candle_open = quote_data["open"].as_a[-2]?.try(&.as_f?)
        pm_open = quote_data["open"][0].as_f?

        time = meta_data["currentTradingPeriod"]["pre"]["end"].as_i
        index = chart_data["timestamp"].as_a.index { |timestamp| timestamp.as_i > time } if chart_data["timestamp"]?
        pm_close = if index
          quote_data["close"][index - 1].as_f?
        else
          quote_data["close"].as_a.last.as_f?
        end

        halt_direction = unless last_candle_open.nil? || halt_price.nil?
          last_candle_open < halt_price ? "up" : "down"
        else
          "intederminable"
        end

        return [halt_price, last_close, today_open, last_candle_open, pm_open, pm_close, halt_direction]
      end
    else
      return ["error", raw["error"]["description"].as_s]
    end
  end

  def self.parse_halt(raw_html : String)
    parser = Myhtml::Parser.new(raw_html)

    date, time, ticker, name, market, stopcode, pausprice, res_date, res_quote_time, res_trade_time = parser.nodes(:td).map(&.inner_text.strip).to_a
    return Halt.new(date, time, ticker, name, market, stopcode, pausprice, res_date, res_quote_time, res_trade_time)
  end
end
