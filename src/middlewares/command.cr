class Shrkbot::Command
  getter names : Array(String)

  # Array in case of aliases
  def initialize(names : String | Array(String))
    @names = if names.is_a?(String)
               [names.downcase]
             else
               names.map { |name| name.downcase }
             end
  end

  def call(payload : Discord::Message, ctx : Discord::Context)
    guild = Shrkbot.bot.cache.resolve_channel(payload.channel_id).guild_id

    prefix = Prefix.get_prefix(guild)

    cmd = payload.content.downcase
    @names.each do |name|
      yield if cmd.starts_with?("#{prefix}#{name} ") || cmd == prefix + name
    end
  end
end
