# frozen_string_literal: true

module Bot
  module CommandPermissions
    module_function

    def permitted?(event:, owner_only:, required_permissions: [])
      return true if owner?(event)
      return false if owner_only

      required_permissions.all? { |permission| event.user.permission?(permission) }
    end

    def owner?(event)
      owner_id = Config.owner_id
      return false if owner_id.blank?

      event.user.id.to_s == owner_id.to_s
    end
  end
end
