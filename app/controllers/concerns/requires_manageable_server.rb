# frozen_string_literal: true

module RequiresManageableServer
  extend ActiveSupport::Concern

  include SetsManageableServers
  include DiscordReauth

  included do
    before_action :require_manageable_server
    helper_method :server_switcher
  end

  private

  def require_manageable_server
    @server_configuration = ServerConfiguration.find_by(discord_id: params[:server_id])
    return if @server_configuration && manageable_now?(params[:server_id])

    redirect_to servers_path, alert: t("servers.not_found")
  end

  def manageable_now?(discord_id)
    live_manageable_ids.include?(discord_id.to_i)
  end

  def live_manageable_ids
    ids = ManageableServers.cached_for(session[:discord_token]).map(&:id)
    remember_manageable_servers(ServerConfiguration.configured_ids_among(ids))
    session.delete(:reauth_attempted)
    ids
  rescue Bot::Discord::UserGuilds::Unauthorized
    raise
  rescue Bot::Discord::UserGuilds::Error
    manageable_server_ids
  end

  def server_switcher
    @server_switcher ||= CachedDashboard.for(
      discord_id: params[:server_id].to_i,
      manageable_ids: manageable_server_ids
    )
  end
end
