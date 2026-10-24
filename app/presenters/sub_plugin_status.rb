# frozen_string_literal: true

class SubPluginStatus
  Row = Data.define(:key, :name, :description, :enabled, :configured, :toggle_fields)

  def self.rows(server_configuration, parent:, enabled_keys: server_configuration.enabled_plugin_keys)
    PluginCatalog.visible_sub_plugin_keys(parent, server_configuration).map do |key|
      definition = PluginCatalog.find(key)
      Row.new(
        key:,
        name: definition.name,
        description: definition.description,
        enabled: enabled_keys.include?(key),
        configured: definition.prerequisites_met?(server_configuration, enabled_keys:),
        toggle_fields: block_given? ? yield(key) : {}
      )
    end
  end
end
