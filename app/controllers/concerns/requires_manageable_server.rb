# frozen_string_literal: true

module RequiresManageableServer
  extend ActiveSupport::Concern

  include SetsVisibleServers
  include DiscordReauth

  included do
    before_action :require_manageable_server
    before_action :require_plugin_access
    helper_method :server_switcher, :plugin_access
  end

  private

  def require_manageable_server
    @server_configuration = ServerConfiguration.find_by(discord_id: params[:server_id])
    return if @server_configuration && visible_now?(params[:server_id])

    redirect_to servers_path, alert: t("servers.not_found")
  end

  def require_plugin_access
    return if plugin_access.manage?(plugin_key)

    redirect_to server_path(params[:server_id]), alert: plugin_access_alert
  end

  def plugin_access_alert
    plugin_access.visible?(plugin_key) ? t("servers.plugin_locked") : t("servers.unknown_plugin")
  end

  def plugin_key
    controller_name.to_sym
  end

  def server_switcher
    @server_switcher ||= CachedDashboard.for(
      discord_id: params[:server_id].to_i,
      manageable_ids: visible_server_ids
    )
  end
end
