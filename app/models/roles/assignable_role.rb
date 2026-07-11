# frozen_string_literal: true

module Roles
  class AssignableRole < ApplicationRecord
    self.table_name = "assignable_roles"

    belongs_to :role_set, class_name: "Roles::Set", inverse_of: :assignable_roles

    validates :role_id, presence: true, uniqueness: {scope: :role_set_id}
  end
end
