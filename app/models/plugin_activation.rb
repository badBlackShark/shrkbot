class PluginActivation < ApplicationRecord
  belongs_to :server_configuration
  belongs_to :plugin

  validates :plugin_id, uniqueness: {scope: :server_configuration_id}

  # Backstop for #21: TogglePlugin gives the friendly failure, but this catches
  # any write that skips the op (raw console, a web bug, a stale object).
  validate :enabling_requires_prerequisites

  private

  def enabling_requires_prerequisites
    return unless enabled?

    definition = PluginCatalog.find(plugin.key)
    return if definition.nil? || definition.prerequisites_met?(server_configuration)

    errors.add(:enabled, "requires the plugin's settings to be configured first")
  end
end
