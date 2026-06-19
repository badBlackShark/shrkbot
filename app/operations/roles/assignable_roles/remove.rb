module Ops
  module Roles
    module AssignableRoles
      class Remove < ApplicationOperation
        receives :assignable_role

        def execute
          assignable_role.destroy!
          ok(assignable_role)
        end
      end
    end
  end
end
