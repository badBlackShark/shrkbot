# frozen_string_literal: true

class Views::Servers::PluginConfigShow < Views::Base
  def initialize(server_configuration:, user:, enabled:)
    @config = server_configuration
    @user = user
    @enabled = enabled
  end

  def view_template
    render Components::PluginShell.new(user: @user, server_configuration: @config, active_key: plugin_key) do
      render Components::ConfigPage.new(
        header: Components::ConfigPageHeader.new(
          icon:,
          title: t(".title"),
          description: t(".description")
        ),
        server_configuration: @config,
        url:,
        toggle: {field: "#{plugin_key}[enabled]", enabled: @enabled},
        gate: {type: :enable, message: t(".gate_message")},
        channel_lost: @enabled && channel_setting.channel_id.nil?
      ) do
        form
      end
    end
  end

  private

  def plugin_key
    raise AbstractMethodError, "#{self.class} must implement #plugin_key"
  end

  def icon
    raise AbstractMethodError, "#{self.class} must implement #icon"
  end

  def url
    raise AbstractMethodError, "#{self.class} must implement #url"
  end

  def form
    raise AbstractMethodError, "#{self.class} must implement #form"
  end

  def channel_setting
    @config.public_send(PluginCatalog.find(plugin_key).channel_setting)
  end
end
