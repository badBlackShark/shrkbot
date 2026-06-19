module Ops
  module Roles
    module AssignableRoles
      class Add < ApplicationOperation
        receives :role_set, :role_id, :label
        receives :description, optional: true
        receives :emoji, optional: true

        def call
          role = role_set.assignable_roles.create!(
            role_id: role_id,
            label: label,
            description: description,
            emoji: emoji,
            position: next_position
          )
          ok(role)
        end

        private

        def next_position
          (role_set.assignable_roles.maximum(:position) || -1) + 1
        end
      end
    end
  end
end
