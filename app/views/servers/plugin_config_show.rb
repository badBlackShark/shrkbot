# frozen_string_literal: true

class Views::Servers::PluginConfigShow < Views::Base
  def initialize(server_configuration:, user:, enabled: false)
    @config = server_configuration
    @user = user
    @enabled = enabled
  end

  def view_template
    render Components::PluginShell.new(user: @user, server_configuration: @config, active_key: plugin_key) do
      render Components::ConfigPage.new(
        header:,
        server_configuration: @config,
        url:,
        toggle:,
        gate:,
        channel_lost: channel_lost?,
        parent_crumb:
      ) do
        body
      end
      after_config_page
    end
  end

  private

  def header
    Components::ConfigPageHeader.new(
      icon:,
      title: t(".title"),
      description: t(".description"),
      badge:
    )
  end

  def url
    PluginPaths.for(@config, plugin_key)
  end

  def toggle
    {field: "#{plugin_key}[enabled]", enabled: enabled?}
  end

  def gate
    {type: :enable, message: t(".gate_message")}
  end

  def enabled?
    @enabled
  end

  def badge
    nil
  end

  def parent_crumb
    nil
  end

  def after_config_page
    nil
  end

  def channel_lost?
    definition = PluginCatalog.find(plugin_key)
    return false unless definition&.channel_backed?

    enabled? && @config.public_send(definition.channel_setting).channel_id.nil?
  end
end
