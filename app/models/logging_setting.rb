# frozen_string_literal: true

class LoggingSetting < ApplicationRecord
  belongs_to :server_configuration

  def action_enabled?(action)
    enabled_actions[action.to_s] == true
  end
end
