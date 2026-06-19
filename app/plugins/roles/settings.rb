module Roles
  class Settings < ApplicationRecord
    self.table_name = "role_settings"

    belongs_to :server_configuration
    has_many :role_sets, -> { order(:position) }, class_name: "Roles::Set",
      foreign_key: "role_setting_id", dependent: :destroy
  end
end
