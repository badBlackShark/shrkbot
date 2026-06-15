class PluginActivation < ApplicationRecord
  belongs_to :server_configuration
  belongs_to :plugin

  validates :plugin_id, uniqueness: { scope: :server_configuration_id }

  # ponytail: "can't enable without required settings" (#21) is enforced in the
  # enable Operation (Phase 3), where the settings are known — not here.
end
