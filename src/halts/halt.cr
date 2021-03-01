class Halt
  getter date : String
  getter time : String
  getter ticker : String
  getter name : String
  getter market : String
  getter stopcode : String
  getter pauseprice : String
  getter res_date : String
  getter res_quote_time : String
  getter res_trade_time : String
  getter halt_price : Float64
  getter last_close : Float64
  getter today_open : Float64
  getter last_candle_open : Float64
  getter pm_open : Float64
  getter pm_close : Float64
  getter last_candle_percent_change : Float64
  getter pre_market_percent_change : Float64
  getter percent_change_since_last_close : Float64
  getter halt_direction : String
  property resume_price : Float64
  property halt_nr : Int32
  property donation_msg : Bool
  property display_price_action : Bool = true
  property price_action_error : String?

  @location = Time::Location.load("America/New_York")

  def initialize(
    @date : String,
    @time : String,
    @ticker : String,
    @name : String,
    @market : String,
    @stopcode : String,
    @pauseprice : String,
    @res_date : String,
    @res_quote_time : String,
    @res_trade_time : String,
    @donation_msg : Bool = false,
    @halt_price : Float64 = -1,
    @last_close : Float64 = -1,
    @today_open : Float64 = -1,
    @last_candle_open : Float64 = -1,
    @last_candle_percent_change : Float64 = -1,
    @pm_open : Float64 = -1,
    @pm_close : Float64 = -1,
    @pre_market_percent_change : Float64 = -1,
    @percent_change_since_last_close : Float64 = -1,
    @halt_direction : String = "indeterminable",
    @resume_price : Float64 = -1,
    @halt_nr : Int32 = 0
  )
    # Sometimes tickers have an '=' at the end for no apparent reason, so we fix this manually.
    @ticker = @ticker[0..-2] if @ticker[-1] == '='
  end

  def set_price_action(
    halt_price,
    last_close,
    today_open,
    last_candle_open,
    pm_open,
    pm_close,
    halt_direction
  )
    @halt_price = halt_price.to_f.round(2) if halt_price
    @last_close = last_close.to_f.round(2) if last_close
    @today_open = today_open.to_f.round(2) if today_open
    @last_candle_open = last_candle_open.to_f.round(2) if last_candle_open
    @pm_open = pm_open.to_f.round(2) if pm_open
    @pm_close = pm_close.to_f.round(2) if pm_close
    @halt_direction = halt_direction.to_s if halt_direction
    @pre_market_percent_change = ((@pm_close - @pm_open) / @pm_open * 100).round(2)
    if @resume_price == -1
      @percent_change_since_last_close = ((@halt_price - @last_close) / @last_close * 100).round(2)
    else
      @percent_change_since_last_close = ((@resume_price - @last_close) / @last_close * 100).round(2)
    end
    @last_candle_percent_change = ((@halt_price - @last_candle_open) / @last_candle_open * 100).round(2)
  end

  def set_price_action_by_other(other : Halt)
    @halt_price = other.halt_price
    @last_close = other.last_close
    @today_open = other.today_open
    @last_candle_open = other.last_candle_open
    @last_candle_percent_change = other.last_candle_percent_change
    @pm_open = other.pm_open
    @pm_close = other.pm_close
    @pre_market_percent_change = other.pre_market_percent_change
    @percent_change_since_last_close = other.percent_change_since_last_close
    @halt_direction = other.halt_direction
  end

  def to_embed
    embed = Discord::Embed.new

    if @donation_msg
      embed.description = "Want to support the project? Consider [donating](https://paypal.me/trueblackshark). For more information, please use the `donate` command."
    end

    if @res_trade_time.empty?
      embed.title = "$#{@ticker} has been halted with code *#{@stopcode}* at #{@time} ET!"
      embed.colour = if @halt_direction == "up"
                       0x00FF00.to_u32
                     elsif @halt_direction == "down"
                       0xFF0000.to_u32
                     else
                       0x000001.to_u32 # Because 0x0 is transparent for Discord, not black.
                     end
    else
      embed.title = "$#{@ticker} has been resumed at #{@res_trade_time} ET! It had been halted with code *#{@stopcode}* at #{@time} ET!"
      embed.colour = 0x38AFE5
    end

    fields = Array(Discord::EmbedField).new

    value = String.build do |str|
      str << "• Ticker: **$#{@ticker}**\n"
      str << "• Name: #{@name}\n"
      str << "• Price at pause: #{@pauseprice}\n" unless @pauseprice.empty?
      str << "• Market: #{@market}"
    end
    fields << Discord::EmbedField.new(name: "Company Info", value: value)

    value = String.build do |str|
      stopcode = CodeList.find_code(@stopcode)
      str << "• Stop Code: **#{stopcode.symbol}**\n"
      str << "• Reason: #{stopcode.title}\n"
      str << "• Number of halts today on this ticker: #{@halt_nr == 0 ? "Unknown (error)" : "**#{@halt_nr}**"}\n"
      str << "\nFor more info on this stopcode use the `stopcode <code>` command." if stopcode.description
    end
    fields << Discord::EmbedField.new(name: "Halt Info", value: value)

    time = Time.local(@location)
    day = time.day.to_s.rjust(2, '0')
    month = time.month.to_s.rjust(2, '0')
    year = time.year.to_s
    date = "#{month}/#{day}/#{year}"
    value = String.build do |str|
      str << "• Time of halt: **#{@time}**\n"
      str << "• Resumption time (trading): **#{@res_trade_time.empty? ? "Not specified" : @res_trade_time}**\n\n"

      if date != @date
        str << "• Date of halt: #{@date}\n"
        str << "• Resumption date: #{@res_date.empty? ? "Not specified" : @res_date}\n"
      end
    end
    fields << Discord::EmbedField.new(name: "Dates & Times", value: value)

    if @display_price_action
      if(pae = @price_action_error)
        fields << Discord::EmbedField.new(name: "Price Action", value: pae)
      else
        if @res_trade_time.empty?
          value = String.build do |str|
            str << "• Last known price: **#{@halt_price == -1 ? "Unknown" : "$#{@halt_price}"}** "
            str << "(#{("%+20.2f" % @percent_change_since_last_close).strip}% since last close)" unless @halt_price == -1
            str << "\n"

            str << "• Price at last close: #{@last_close == -1 ? "Unknown" : "$#{@last_close}"}\n"

            pm = @pm_open == -1 || @pm_close == -1
            str << "• Today's pre-market move: #{pm ? "Unknown" : "$#{@pm_open} -> $#{@pm_close}"} "
            str << "(#{("%+20.2f" % @pre_market_percent_change).strip}%)" unless pm
            str << "\n"

            str << "• Price at market open: #{@today_open == -1 ? "Unknown" : "$#{@today_open}"}\n" if @pm_close != @today_open

            last_move = @last_candle_open == -1 || @halt_price == -1
            str << "• Last known price movement: #{last_move ? "Unknown" : "$#{@last_candle_open} -> $#{@halt_price}"} "
            str << "(#{("%+20.2f" % @last_candle_percent_change).strip}%)" unless last_move
            str << "\n"

            str << "• Suspected halt direction: **#{@halt_direction.capitalize}**"
          end
        else
          value = String.build do |str|
            str << "• Price at halt: $#{@halt_price == -1 ? "Unknown" : @halt_price}\n"

            str << "• Resumed at: **$#{@resume_price == -1 ? "Unknown" : @resume_price.round(2)}** "
            str << "(#{("%+20.2f" % @percent_change_since_last_close).strip}% since last close)" unless @resume_price == -1
            str << "\n"

            str << "• Suspected halt direction: #{@halt_direction.capitalize}\n"
            str << "• Price at market open: $#{@today_open == -1 ? "Unknown" : @today_open}"
          end
        end

        fields << Discord::EmbedField.new(name: "Price Action", value: value)
      end
    end

    embed.fields = fields
    embed.footer = Discord::EmbedFooter.new(text: "All times are in Eastern Time. All dates are in MM/DD/YYYY. The correctness of the data displayed is not guaranteed.")

    return embed
  end

  def to_embed_field
    name = "#{@date} at #{@time}"
    value = "**$#{@ticker}** was halted with stopcode **#{@stopcode}**. "
    value += if @res_trade_time.empty?
               "Trading has yet to be resumed. "
             else
               "Trading was resumed on #{@res_date} at #{@res_trade_time}. "
             end
    value += "The suspected halt direction was #{@halt_direction}."

    return Discord::EmbedField.new(name: name, value: value)
  end

  def ==(other : Halt)
    @date == other.date &&
      @time == other.time &&
      @ticker == other.ticker &&
      @name == other.name &&
      @market == other.market &&
      @stopcode == other.stopcode &&
      @pauseprice == other.pauseprice &&
      @res_date == other.res_date &&
      @res_quote_time == other.res_quote_time &&
      @res_trade_time == other.res_trade_time
  end
end
