class Shrkbot::PermissionChecker
  def initialize(@required : PermissionLevel, @warn : Bool = false)
  end

  def call(payload : Discord::Message, ctx : Discord::Context)
    client = ctx[Discord::Client]
    guild = client.cache.try &.resolve_channel(payload.channel_id).guild_id

    if Permissions.permission_level(payload.author.id, guild) >= @required
      yield
    elsif @warn
      client.create_message(payload.channel_id, "You need at least #{@required.to_s.downcase} level permissions to use this command.")
    end
  end
end
