# frozen_string_literal: true

class Views::Servers::Feeds::Show < Views::Servers::SubPluginShow
  def initialize(plugin_key:, tab: nil, **)
    @plugin_key = plugin_key
    @tab = tab
    super(**)
  end

  private

  attr_reader :plugin_key

  def header
    Components::ConfigPageHeader.new(
      icon:,
      title: t("views.servers.#{plugin_key}.show.title"),
      description: PluginCatalog.find(plugin_key).description,
      badge:
    )
  end

  def toggle
    super.merge(instant: true)
  end

  def body
    render Components::Feeds::PluginBody.new(server_configuration: @config, plugin_key:, selected: @tab)
  end
end
