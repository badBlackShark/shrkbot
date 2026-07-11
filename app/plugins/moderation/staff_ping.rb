# frozen_string_literal: true

module Moderation
  module StaffPing
    module_function

    def prefix(staff_role_id, ping: true)
      return "" unless ping

      "<@&#{staff_role_id}>: "
    end

    def allowed_roles(staff_role_id, ping: true)
      return [] unless ping

      [staff_role_id].compact
    end
  end
end
