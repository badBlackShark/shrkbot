# frozen_string_literal: true

module SetsVisibleServers
  extend ActiveSupport::Concern

  SESSION_KEY = :authorized_server_ids
  MANAGED_SESSION_KEY = :managed_server_ids

  private

  def visible_servers
    @visible_servers ||= begin
      servers = VisibleServers.for(session[:discord_token], current_user.discord_id)
      remember_server_access(servers)
      session.delete(:reauth_attempted)
      servers
    end
  end

  def remember_server_access(servers)
    configured = ServerConfiguration.configured_ids_among(servers.map(&:id))
    session[SESSION_KEY] = configured
    session[MANAGED_SESSION_KEY] = configured & servers.select(&:manageable?).map(&:id)
  end

  def visible_server_ids
    Array(session[SESSION_KEY])
  end

  def managed_server_ids
    Array(session[MANAGED_SESSION_KEY])
  end

  def live_access
    @live_access ||= begin
      visible_servers.to_h { |server| [server.id, server.manageable?] }
    rescue Bot::Discord::UserGuilds::Unauthorized
      raise
    rescue Bot::Discord::UserGuilds::Error
      visible_server_ids.index_with { |id| managed_server_ids.include?(id) }
    end
  end

  def visible_now?(discord_id)
    live_access.key?(discord_id.to_i)
  end

  def manages_now?(discord_id)
    live_access[discord_id.to_i] == true
  end

  def plugin_access
    @plugin_access ||= PluginAccess.new(
      user: current_user,
      server_configuration: @server_configuration,
      manages_server: manages_now?(@server_configuration.discord_id)
    )
  end
end
