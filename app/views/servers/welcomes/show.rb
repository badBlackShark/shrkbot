# frozen_string_literal: true

class Views::Servers::Welcomes::Show < Views::Servers::PluginConfigShow
  private

  def plugin_key
    :welcomes
  end

  def icon
    "hand-waving"
  end

  def body
    render Components::Welcomes::ConfigForm.new(server_configuration: @config)
  end
end
