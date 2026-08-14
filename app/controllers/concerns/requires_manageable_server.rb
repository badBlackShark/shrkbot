# frozen_string_literal: true

module RequiresManageableServer
  extend ActiveSupport::Concern

  include SetsVisibleServers
  include DiscordReauth

  included do
    before_action :require_manageable_server
    before_action :block_preview_writes
    before_action :require_plugin_access
    helper_method :server_switcher, :plugin_access
  end

  private

  def require_manageable_server
    @server_configuration = resolve_server_configuration
    return if @server_configuration && (preview_request? || visible_now?(params[:server_id]))

    redirect_to servers_path, alert: t("servers.not_found")
  end

  def resolve_server_configuration
    if preview_request?
      ServerConfiguration.previews.find_by(discord_id: PreviewData.guild[:discord_id])
    else
      ServerConfiguration.real.find_by(discord_id: params[:server_id])
    end
  end

  def block_preview_writes
    return if request.get? || !@server_configuration.preview?

    redirect_back fallback_location: preview_path, alert: t("servers.preview_read_only")
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
      discord_id: switcher_discord_id,
      manageable_ids: switcher_manageable_ids
    )
  end

  def switcher_discord_id
    preview_request? ? @server_configuration.discord_id : params[:server_id].to_i
  end

  def switcher_manageable_ids
    preview_request? ? [@server_configuration.discord_id] : visible_server_ids
  end
end
