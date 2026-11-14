# frozen_string_literal: true

class Views::Servers::GroupShow < Views::Servers::PluginConfigShow
  private

  def toggle
    nil
  end

  def gate
    nil
  end

  def after_config_page
    render Components::SubPluginToggleForms.new(
      server_configuration: @config,
      parent: plugin_key
    )
  end
end
