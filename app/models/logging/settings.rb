# frozen_string_literal: true

module Logging
  class Settings < ApplicationRecord
    self.table_name = "logging_settings"

    belongs_to :server_configuration

    def action_enabled?(action)
      enabled_actions[action.to_s] == true
    end
  end
end
