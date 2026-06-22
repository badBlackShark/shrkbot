# Server-scoped authorization shared by every controller that acts on one
# server. We don't persist which servers a user manages (that's a Discord fact,
# fetched per design #12, not a DB relationship) — so authorization is cached in
# the signed session: the picker and dashboard record the servers the user just
# proved manageable, and mutations check that set rather than re-hitting
# Discord's heavily rate-limited guild-list endpoint.
module ManageableServers
  extend ActiveSupport::Concern

  SESSION_KEY = :authorized_server_ids

  private

  def remember_manageable_servers(discord_ids)
    session[SESSION_KEY] = discord_ids
  end

  def require_manageable_server
    @server_configuration = ServerConfiguration.find_by(discord_id: params[:server_id])
    return if @server_configuration && manageable_server?(params[:server_id])

    redirect_to servers_path, alert: t("servers.not_found")
  end

  def manageable_server?(discord_id)
    Array(session[SESSION_KEY]).include?(discord_id.to_i)
  end
end
