# frozen_string_literal: true

module SetsManageableServers
  extend ActiveSupport::Concern

  SESSION_KEY = :authorized_server_ids

  private

  def remember_manageable_servers(discord_ids)
    session[SESSION_KEY] = discord_ids
  end
end
