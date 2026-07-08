# frozen_string_literal: true

module Moderation
  module StaffPing
    module_function

    def prefix(staff_role_id)
      staff_role_id ? "<@&#{staff_role_id}> " : ""
    end
  end
end
