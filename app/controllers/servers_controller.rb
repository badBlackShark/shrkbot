# frozen_string_literal: true

class ServersController < ApplicationController
  include SetsVisibleServers

  rate_limit to: 60, within: 1.minute, by: -> { session[:user_id] }, only: :index

  before_action :load_dashboard, only: :show

  rescue_from Bot::Discord::UserGuilds::Error, with: :render_error

  include DiscordReauth

  def index
    configured = ServerConfiguration.configured_ids_among(visible_servers.map(&:id))
    present, absent = visible_servers.partition { |server| configured.include?(server.id) }

    render Views::Servers::Index.new(
      present:,
      absent:,
      plugin_counts: PluginActivation.enabled_counts_for(configured),
      user: current_user
    )
  end

  def show
    render Views::Servers::Show.new(
      server: @server,
      server_configuration: @server_configuration,
      plugins: PluginStatus.rows(@server_configuration, access: plugin_access),
      user: current_user,
      servers: @configured_servers,
      plugin_counts: @plugin_counts
    )
  end

  private

  def load_dashboard
    result = ServerDashboard.resolve(
      discord_token: session[:discord_token],
      target_id: params[:id].to_i,
      cached_ids: visible_server_ids,
      admin_discord_id: current_user.discord_id
    )
    return redirect_to(servers_path, alert: t("servers.not_found")) unless result

    @server = result.server
    @server_configuration = result.server_configuration
    @configured_servers = result.configured_servers
    @plugin_counts = result.plugin_counts
  end

  def render_error
    session.delete(:reauth_attempted)
    render Views::Servers::Index.new(present: [], absent: [], plugin_counts: {}, user: current_user, error: true)
  end
end
