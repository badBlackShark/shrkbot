# frozen_string_literal: true

PluginCatalog.all.each do |definition|
  plugin = Plugin.find_or_initialize_by(key: definition.key)
  plugin.update!(name: definition.name, description: definition.description)
end

TwilightStruggle::Tournament.find_or_create_by!(friendly: true) do |tournament|
  tournament.name = I18n.t("twilight_struggle.friendly_tournament_name")
end
