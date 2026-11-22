# frozen_string_literal: true

class Views::Servers::Feeds::Show < Views::Servers::SubPluginShow
  def initialize(plugin_key:, **)
    @plugin_key = plugin_key
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
    render Components::Feeds::SubscriptionList.new(server_configuration: @config, source: ::Feeds.source(plugin_key))
  end
end
