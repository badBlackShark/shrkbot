# frozen_string_literal: true

PluginCatalog.all.each do |definition|
  plugin = Plugin.find_or_initialize_by(key: definition.key)
  plugin.update!(name: definition.name, description: definition.description)
end
