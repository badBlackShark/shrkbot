# Runtime permission gate. Defense-in-depth behind Discord's own hiding
# (default_member_permissions): a guild admin can re-grant a command to anyone
# in the integrations UI, so we never trust the hiding alone.
#
# `event` is duck-typed (discordrb interaction): #user.id, and #member that
# responds to #permission?(sym). DM interactions have no member.
module CommandPermissions
  module_function

  # owner_id/required come from the command class; kept as args (not globals)
  # so this stays a pure function.
  def permitted?(event:, required:, owner_only:, owner_id:)
    return true if owner?(event, owner_id) # creator override beats everything
    return false if owner_only
    return true if required.empty?

    member = event.respond_to?(:member) ? event.member : nil
    return false unless member # perms can't be met without a guild member

    required.all? { |perm| member.permission?(perm) }
  end

  def owner?(event, owner_id)
    return false if owner_id.nil? || owner_id.to_s.empty?

    event.user.id.to_s == owner_id.to_s
  end
end
