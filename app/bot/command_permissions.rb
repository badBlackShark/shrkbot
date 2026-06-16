# Re-checked at runtime even though Discord hides commands the member can't use:
# that hiding can be overridden server-side, so it can't be trusted alone.
module CommandPermissions
  module_function

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
