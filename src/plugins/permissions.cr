class Shrkbot::Permissions
  include Discord::Plugin

  @@permissions = Hash(Discord::Snowflake, Hash(Discord::Snowflake, PermissionLevel)).new

  getter! perm_role : Discord::Role

  @[Discord::Handler(
    event: :guild_create
  )]
  def init_permissions(payload)
    spawn do
      @@permissions[payload.id] = Hash(Discord::Snowflake, PermissionLevel).new

      @perm_role = client.get_guild_roles(payload.id).find { |role| role.name.downcase == "botcommand" }
      unless @perm_role
        @perm_role = client.create_guild_role(payload.id, "BotCommand")
      end

      mods = payload.members.select { |member| member.roles.includes?(self.perm_role.id) }
      mods.each do |mod|
        next if mod.user.id == Shrkbot.config.owner_id
        @@permissions[payload.id][mod.user.id] = PermissionLevel::Moderator
      end
    end
  end

  @[Discord::Handler(
    event: :guild_member_update
  )]
  def recheck_for_role(payload)
    if payload.roles.includes?(self.perm_role.id)
      @@permissions[payload.guild_id][payload.user.id] = PermissionLevel::Moderator
    else
      @@permissions[payload.guild_id].delete(payload.user.id)
    end
  end

  def self.permission_level(user : Discord::Snowflake, guild : Discord::Snowflake? = nil)
    return PermissionLevel::Creator if user == Shrkbot.config.owner_id
    return PermissionLevel::Moderator if @@permissions[guild]? && @@permissions[guild][user]?
    return PermissionLevel::User
  end
end
