# frozen_string_literal: true

module CommandPermissions
  module_function

  def permitted?(event:, owner_only:)
    return true if owner?(event)

    !owner_only
  end

  def owner?(event)
    owner_id = BotConfig.owner_id
    return false if owner_id.blank?

    event.user.id.to_s == owner_id.to_s
  end
end
