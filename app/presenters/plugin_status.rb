# frozen_string_literal: true

class PluginStatus
  Row = Data.define(:key, :enabled, :configured, :locked, :manageable, :toggleable) do
    def initialize(key:, enabled:, configured:, locked: false, manageable: true, toggleable: true)
      super
    end
  end

  def self.rows(server_configuration, access:)
    activations = server_configuration.plugin_activations.includes(:plugin).index_by { |activation| activation.plugin.key }
    enabled_keys = server_configuration.enabled_plugin_keys
    catalog_rows = PluginCatalog.visible_for(server_configuration).map do |definition|
      Row.new(
        key: definition.key,
        enabled: activations[definition.key]&.enabled? || false,
        configured: definition.prerequisites_met?(server_configuration, enabled_keys:),
        manageable: access.manage?(definition.key),
        toggleable: access.toggle?(definition.key)
      )
    end
    catalog_rows + global_rows(access)
  end

  def self.row(server_configuration, plugin, access:)
    activation = server_configuration.plugin_activations.find_by(plugin:)
    Row.new(
      key: plugin.key,
      enabled: activation&.enabled? || false,
      configured: PluginCatalog.find(plugin.key).prerequisites_met?(server_configuration, enabled_keys: server_configuration.enabled_plugin_keys),
      manageable: access.manage?(plugin.key),
      toggleable: access.toggle?(plugin.key)
    )
  end

  def self.global_rows(access)
    PluginCatalog::GLOBAL_KEYS.map do |key|
      Row.new(key:, enabled: true, configured: true, locked: true, manageable: access.manage?(key), toggleable: access.toggle?(key))
    end
  end
  private_class_method :global_rows
end
