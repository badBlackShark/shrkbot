# frozen_string_literal: true

class Views::Servers::Logging::Show < Views::Servers::PluginConfigShow
  private

  def plugin_key
    :logging
  end

  def icon
    "scroll"
  end

  def body
    render Components::Logging::ConfigForm.new(server_configuration: @config)
  end
end
