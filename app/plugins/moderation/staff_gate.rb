# frozen_string_literal: true

module Moderation
  module StaffGate
    module_function

    def allows?(member, staff_role_id)
      return false unless member
      return true if staff_role_id && member.roles.any? { |role| role.id == staff_role_id }

      member.permission?(:manage_messages)
    end
  end
end
