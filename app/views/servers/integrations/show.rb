# frozen_string_literal: true

class Views::Servers::Integrations::Show < Views::Servers::PluginConfigShow
  private

  def plugin_key
    :integrations
  end

  def body
    render Components::Integrations::Overview.new(server_configuration: @config)
  end

  def after_config_page
    render Components::SubPluginToggleForms.new(
      server_configuration: @config,
      parent: :integrations
    )
  end
end
