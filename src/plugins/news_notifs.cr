class Shrkbot::NewsNotifs
  include Discord::Plugin

  class_getter! api : YahooFinance::Api

  @first = true

  @[Discord::Handler(
    event: :guild_create
  )]
  def init_halts(payload)
    spawn do
      if @first
        @first = false
        @@api = YahooFinance::Api.new(Shrkbot.config.yahoo_token)
      end

      HaltNotifs.setup(payload.id, client) if PluginSelector.enabled?(payload.id, "news")
    end
  end

  def self.setup(guild : Discord::Snowflake, client : Discord::Client)
    # Nothing yet. Will be built in the future
  end

  @[Discord::Handler(
    event: :message_create,
    middleware: {
      Command.new("news"),
      EnabledChecker.new("news"),
      ArgumentChecker.new(1)
    }
  )]
  def news_for_ticker(payload, ctx)
    ticker = ctx[ArgumentChecker::Result].args.first.upcase
    news = get_news(ticker)
    if news.is_a?(String)
      client.create_message(payload.channel_id, "News couldn't be fetched due to an error on Yahoo Finance's side. Error: #{news}")
    else
      if news.empty?
        client.create_message(payload.channel_id, "No news in the past week for $#{ticker}. Either there are none, or you misspelled the ticker.")
      else
        embed = Discord::Embed.new
        embed.title = "News for $#{ticker} from the past week."
        embed.colour = 0xFFE600

        embed.fields = news[0..2].map(&.to_embed_field(ticker))

        embed.footer = Discord::EmbedFooter.new(text: "Only showing the three most recent items.") if news.size > 3

        client.create_message(payload.channel_id, "", embed)
      end
    end
  end

  private def get_news(symbol : String)
    begin
      raw = NewsNotifs.api.get_news(symbol)
    rescue e : Exception
      return e.message.not_nil!
    end

    news = raw["items"]["result"].as_a.map { |n| News.from_json(n.to_json) }
    news.select { |n| Time.unix(n.published_at) > 1.week.ago }.sort_by { |n| n.published_at }.reverse
  end
end
