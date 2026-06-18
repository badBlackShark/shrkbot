PluginCatalog.all.each do |definition|
  plugin = Plugin.find_or_initialize_by(key: definition.key)
  plugin.update!(name: definition.name, description: definition.description, default_enabled: definition.default_enabled)
end
