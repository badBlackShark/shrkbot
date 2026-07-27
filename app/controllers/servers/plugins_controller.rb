# frozen_string_literal: true

class Servers::PluginsController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin

  before_action :set_plugin
  before_action :require_toggle_access, only: :update

  def update
    result = Ops::ServerConfiguration::Plugins::Toggle.call(
      server_configuration: @server_configuration,
      plugin: @plugin,
      enabled: params[:enabled]
    )
    @row = PluginStatus.row(@server_configuration, @plugin, access: plugin_access)
    @toast = feedback(result)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: server_path(params[:server_id]) }
    end
  end

  private

  def plugin_key
    params[:key].to_sym
  end

  def feedback(result)
    return {level: "alert", message: result.errors.to_sentence} if result.failure?

    key = result.value.enabled? ? "servers.plugin_enabled" : "servers.plugin_disabled"
    {level: "notice", message: t(key, plugin: @plugin.name)}
  end

  def set_plugin
    @plugin = Plugin.find_by(key: params[:key])
    redirect_to server_path(params[:server_id]), alert: t("servers.unknown_plugin") unless @plugin
  end
end
