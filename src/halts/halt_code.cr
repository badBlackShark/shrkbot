class HaltCode
  getter symbol : String
  getter title : String
  getter description : String?

  def initialize(@symbol : String, @title : String, @description : String? = nil)
  end

  def to_embed
    embed = Discord::Embed.new

    embed.title = @symbol

    desc = @title
    desc += "\n\n#{@description}" if description
    embed.description = desc
    embed.colour = 0x38AFE5

    return embed
  end
end
