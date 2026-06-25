# frozen_string_literal: true

class PluginStatus
  Row = Data.define(:key, :enabled, :configured)

  def self.rows(server_configuration)
    activations = server_configuration.plugin_activations.includes(:plugin).index_by { |activation| activation.plugin.key }
    PluginCatalog.all.map do |definition|
      Row.new(
        key: definition.key,
        enabled: activations[definition.key]&.enabled? || false,
        configured: definition.prerequisites_met?(server_configuration)
      )
    end
  end

  def self.row(server_configuration, plugin)
    activation = server_configuration.plugin_activations.find_by(plugin:)
    Row.new(
      key: plugin.key,
      enabled: activation&.enabled? || false,
      configured: PluginCatalog.find(plugin.key).prerequisites_met?(server_configuration)
    )
  end
end
