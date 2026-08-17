# frozen_string_literal: true

class Views::Servers::Lfg::Show < Views::Servers::PluginConfigShow
  private

  def plugin_key
    :lfg
  end

  def icon
    "game-controller"
  end

  def body
    render Components::Lfg::ConfigForm.new(server_configuration: @config)
  end
end
