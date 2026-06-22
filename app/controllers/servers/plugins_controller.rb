class Servers::PluginsController < ApplicationController
  include ManageableServers

  before_action :require_login
  before_action :require_manageable_server
  before_action :set_plugin

  def update
    result = Ops::ServerConfiguration::Plugins::Toggle.call(
      server_configuration: @server_configuration,
      plugin: @plugin,
      enabled: params[:enabled]
    )

    respond_to do |format|
      format.turbo_stream { render turbo_stream: render_to_string(stream(result), layout: false) }
      format.html { redirect_back fallback_location: server_path(params[:server_id]) }
    end
  end

  private

  def stream(result)
    level, message = feedback(result)
    Components::TurboStream.new
      .replace("plugin-#{@plugin.key}", plugin_row)
      .append("toasts", Components::Toast.new(level:, message:))
  end

  def plugin_row
    row = PluginStatus.row(@server_configuration, @plugin)
    Components::PluginRow.new(server_id: params[:server_id], key: row.key, enabled: row.enabled, configured: row.configured)
  end

  def feedback(result)
    return ["alert", result.errors.to_sentence] if result.failure?

    key = result.value.enabled? ? "servers.plugin_enabled" : "servers.plugin_disabled"
    ["notice", t(key, plugin: @plugin.name)]
  end

  def set_plugin
    @plugin = Plugin.find_by(key: params[:key])
    redirect_to server_path(params[:server_id]), alert: t("servers.unknown_plugin") unless @plugin
  end
end
