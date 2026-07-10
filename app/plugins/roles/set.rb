# frozen_string_literal: true

module Roles
  class Set < ApplicationRecord
    self.table_name = "role_sets"

    belongs_to :role_setting, class_name: "Roles::Settings"
    has_many :assignable_roles, -> { order(:position) }, class_name: "Roles::AssignableRole",
      foreign_key: "role_set_id", dependent: :delete_all

    validates :name, presence: true
    validates :selection_mode, presence: true
    enum :selection_mode, {single: "single", multi: "multi"}, validate: {allow_nil: true}

    def channel_id
      channel_override || role_setting.channel_id
    end
  end
end
