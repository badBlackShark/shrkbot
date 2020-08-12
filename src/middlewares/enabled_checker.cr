class Shrkbot::EnabledChecker
  def initialize(@plugin : String)
  end

  def call(payload, ctx)
    client = ctx[Discord::Client]
    guild = if payload.is_a?(Discord::Gateway::GuildCreatePayload)
              payload.id
            else # MessageCreatePayload
              client.cache.try &.resolve_channel(payload.channel_id).guild_id
            end
    yield if PluginSelector.enabled?(guild, @plugin)
  end
end
