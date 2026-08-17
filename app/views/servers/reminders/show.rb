# frozen_string_literal: true

class Views::Servers::Reminders::Show < Views::Servers::PluginConfigShow
  private

  def plugin_key
    :reminders
  end

  def icon
    "bell-ringing"
  end

  def badge
    t(".badge")
  end

  def toggle
    nil
  end

  def gate
    nil
  end

  def body
    render Components::Reminders::ConfigForm.new(server_configuration: @config)
  end
end
