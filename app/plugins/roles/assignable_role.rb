module Roles
  class AssignableRole < ApplicationRecord
    self.table_name = "assignable_roles"

    belongs_to :role_set, class_name: "Roles::Set"

    validates :role_id, presence: true, uniqueness: {scope: :role_set_id}
  end
end
