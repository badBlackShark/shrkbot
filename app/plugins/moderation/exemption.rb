# frozen_string_literal: true

module Moderation
  module Exemption
    module_function

    def exempt?(member:, server:, staff_role_id:)
      return true if member.id == server.owner.id
      return false unless staff_role_id

      member.roles.any? { |role| role.id == staff_role_id }
    end
  end
end
