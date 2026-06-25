# frozen_string_literal: true

module RequiresManageableServer
  extend ActiveSupport::Concern

  included do
    before_action :require_manageable_server
  end

  private

  def require_manageable_server
    @server_configuration = ServerConfiguration.find_by(discord_id: params[:server_id])
    return if @server_configuration && manageable_server?(params[:server_id])

    redirect_to servers_path, alert: t("servers.not_found")
  end

  def manageable_server?(discord_id)
    Array(session[SetsManageableServers::SESSION_KEY]).include?(discord_id.to_i)
  end
end
