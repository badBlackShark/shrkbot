require "humanize_time"

class News
  include JSON::Serializable

  property uuid : String
  property title : String
  property link : String
  property summary : String
  property publisher : String
  property author : String
  property type : String
  property entities : Array(Entity)
  property offnet : Bool
  property content : String?
  @[JSON::Field(ignore: true)] # Not needed and tedious to parse
  property streams : Nil
  property ignore_main_image : Bool
  property published_at : Int64
  @[JSON::Field(ignore: true)] # Not needed and tedious to parse
  property main_image : Nil
  property is_magazine : Bool
  property reference_id : String

  def short_form
    "• #{title} [published **#{HumanizeTime.distance_of_time_in_words(Time.unix(@published_at), Time.utc)} ago**]\n➔ #{link}"
  end

  def to_embed_field(exclude_ticker : String? = nil)
    name = "#{title} [published **#{HumanizeTime.distance_of_time_in_words(Time.unix(@published_at), Time.utc)} ago**]\n"

    mentioned_tickers = @entities.reject { |e| e.term[7..-1].upcase == exclude_ticker }.map { |e| "$#{e.term[7..-1]}" }
    value = String.build do |str|
      str << "Published by #{@publisher.empty? ? "*unknown*" : @publisher}, written by #{@author.empty? ? "*unknown*" : @author}"
      str << "." unless @author.ends_with?(".") # In case <Company> Inc. wrote the article.
      str << " This article also mentions: #{mentioned_tickers.join(", ")}." unless mentioned_tickers.empty?
      str << "\n➔ #{link}\n"
      str << "**Summary:** #{truncate_summary}\n"
      str << "----------------------------------------"
    end

    return Discord::EmbedField.new(name: name, value: value)
  end

  # Taken from String#truncate from Rails (https://apidock.com/rails/String/truncate)
  private def truncate_summary
    return @summary if @summary.size <= 600

    stop = @summary.rindex(" ", 597) || 597
    return "#{@summary[0, stop]}..."
  end
end
