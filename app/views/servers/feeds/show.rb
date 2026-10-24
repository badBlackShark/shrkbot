# frozen_string_literal: true

class Views::Servers::Feeds::Show < Views::Servers::PluginConfigShow
  private

  def plugin_key
    :feeds
  end

  def icon
    "rss"
  end

  def body
    render Components::Feeds::Overview.new(server_configuration: @config)
  end

  def after_config_page
    render Components::SubPluginToggleForms.new(
      server_configuration: @config,
      parent: :feeds
    )
  end
end
