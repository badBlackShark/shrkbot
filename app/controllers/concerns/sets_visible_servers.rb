# frozen_string_literal: true

module SetsManageableServers
  extend ActiveSupport::Concern

  SESSION_KEY = :authorized_server_ids

  private

  def remember_manageable_servers(discord_ids)
    session[SESSION_KEY] = discord_ids
  end

  def manageable_server_ids
    Array(session[SESSION_KEY])
  end

  def live_manageable_ids
    @live_manageable_ids ||= begin
      ids = ManageableServers.cached_for(session[:discord_token]).map(&:id)
      remember_manageable_servers(ServerConfiguration.configured_ids_among(ids))
      session.delete(:reauth_attempted)
      ids
    rescue Bot::Discord::UserGuilds::Unauthorized
      raise
    rescue Bot::Discord::UserGuilds::Error
      manageable_server_ids
    end
  end

  def manageable_now?(discord_id)
    live_manageable_ids.include?(discord_id.to_i)
  end

  def plugin_access
    @plugin_access ||= PluginAccess.new(
      user: current_user,
      server_configuration: @server_configuration,
      manages_server: manageable_now?(@server_configuration.discord_id)
    )
  end
end
