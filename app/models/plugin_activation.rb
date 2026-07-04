# frozen_string_literal: true

class PluginActivation < ApplicationRecord
  belongs_to :server_configuration
  belongs_to :plugin

  validates :plugin_id, uniqueness: {scope: :server_configuration_id}
  validate :enabling_requires_prerequisites

  def self.enabled_counts_for(discord_ids)
    joins(:server_configuration)
      .where(server_configurations: {discord_id: discord_ids}, enabled: true)
      .group("server_configurations.discord_id")
      .count
  end

  private

  def enabling_requires_prerequisites
    return unless enabled?

    definition = PluginCatalog.find(plugin.key)
    return if definition.nil? || definition.prerequisites_met?(server_configuration)

    errors.add(:enabled, "requires the plugin's settings to be configured first")
  end
end
