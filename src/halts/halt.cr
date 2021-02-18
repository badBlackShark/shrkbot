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
  property halt_nr : Int32

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
    @halt_nr : Int32 = 0
  )
  end

  def to_embed
    embed = Discord::Embed.new

    if @res_trade_time.empty?
      embed.title = "$#{@ticker} has been halted with code *#{@stopcode}* at #{@time} ET!"
      embed.colour = 0xFF0000
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
      str << "• Number of halts today on this ticker: #{@halt_nr}\n" unless @halt_nr == 0
      str << "\nFor more info on this stopcode use the `stopcode <code>` command." if stopcode.description
    end
    fields << Discord::EmbedField.new(name: "Halt Info", value: value)

    value = String.build do |str|
      str << "• Date of halt: #{@date}\n"
      str << "• Time of halt: **#{@time}**\n"
      str << "• Resumption date : #{@res_date.empty? ? "Not specified": @res_date}\n"
      str << "• Resumption time (quotes): #{@res_quote_time.empty? ? "Not specified": @res_quote_time}\n"
      str << "• Resumption time (trading): **#{@res_trade_time.empty? ? "Not specified": @res_trade_time}**"
    end
    fields << Discord::EmbedField.new(name: "Dates & Times", value: value)

    embed.fields = fields
    embed.footer = Discord::EmbedFooter.new(text: "All times are in Eastern Time. All dates are in MM/DD/YYYY.")

    return embed
  end

  def to_embed_field
    name = "#{@date} at #{@time}"
    value = "**$#{@ticker}** was halted with stopcode **#{@stopcode}**. "
    value += if @res_trade_time.empty?
      "Trading has yet to be resumed."
    else
      "Trading was resumed on #{@res_date} at #{@res_trade_time}."
    end

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
