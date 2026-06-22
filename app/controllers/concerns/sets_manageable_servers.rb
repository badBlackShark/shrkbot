# Records which servers the user just proved they manage, so later requests can
# authorize from the signed session instead of re-fetching from Discord. The
# read side is RequiresManageableServer.
module SetsManageableServers
  extend ActiveSupport::Concern

  SESSION_KEY = :authorized_server_ids

  private

  def remember_manageable_servers(discord_ids)
    session[SESSION_KEY] = discord_ids
  end
end
