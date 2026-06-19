module CommandPermissions
  module_function

  def permitted?(event:, required:, owner_only:)
    return true if owner?(event)
    return false if owner_only
    return true if required.empty?

    member = event.respond_to?(:member) ? event.member : nil
    return false unless member

    required.all? { |perm| member.permission?(perm) }
  end

  def owner?(event)
    owner_id = BotConfig.owner_id
    return false if owner_id.to_s.strip.empty?

    event.user.id.to_s == owner_id.to_s
  end
end
