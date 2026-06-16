class PluginActivation < ApplicationRecord
  belongs_to :server_configuration
  belongs_to :plugin

  validates :plugin_id, uniqueness: {scope: :server_configuration_id}

  # The "can't enable without required settings" rule (#21) is enforced in the
  # enable operation, where the settings are known — not here.
end
