class Servers::PluginsController < ApplicationController
  before_action :require_login
  before_action :authorize_server

  def update
    plugin = Plugin.find_by(key: params[:id])
    streams = plugin ? toggle(plugin) : [toast("alert", t("servers.unknown_plugin"))]

    respond_to do |format|
      format.turbo_stream { render turbo_stream: streams }
      format.html { redirect_to server_path(params[:server_id]) }
    end
  end

  private

  def toggle(plugin)
    result = Ops::ServerConfiguration::Plugins::Toggle.call(
      server_configuration: @server_configuration,
      plugin:,
      enabled: params[:enabled]
    )
    [plugin_stream(plugin), toast(*feedback(plugin, result))]
  end

  def feedback(plugin, result)
    return ["alert", result.errors.to_sentence] if result.failure?

    key = result.value.enabled? ? "servers.plugin_enabled" : "servers.plugin_disabled"
    ["notice", t(key, plugin: plugin.name)]
  end

  def plugin_stream(plugin)
    row = PluginStatus.row(@server_configuration, plugin)
    turbo_stream.replace(
      "plugin-#{row.key}",
      render_to_string(Components::PluginRow.new(server_id: params[:server_id], key: row.key, enabled: row.enabled, configured: row.configured), layout: false)
    )
  end

  def toast(level, message)
    turbo_stream.append("toasts", render_to_string(Components::Toast.new(level:, message:), layout: false))
  end

  # Authorize against the set of servers the user proved they manage the last
  # time they loaded the picker or a dashboard, so a toggle never re-hits
  # Discord's heavily rate-limited guild-list endpoint.
  def authorize_server
    @server_configuration = ServerConfiguration.find_by(discord_id: params[:server_id])
    authorized = Array(session[:authorized_server_ids]).include?(params[:server_id].to_i)
    return if @server_configuration && authorized

    redirect_to servers_path, alert: t("servers.not_found")
  end
end
