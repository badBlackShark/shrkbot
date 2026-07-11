# frozen_string_literal: true

class ServersController < ApplicationController
  include SetsManageableServers

  before_action :load_dashboard, only: :show

  rescue_from Bot::Discord::UserGuilds::Error, with: :render_error
  rescue_from Bot::Discord::UserGuilds::Unauthorized, with: :reauthenticate

  def index
    manageable = ManageableGuilds.for(session[:discord_token])
    session.delete(:reauth_attempted)
    configured = ServerConfiguration.configured_ids_among(manageable.map(&:id))
    remember_manageable_servers(configured)
    present, absent = manageable.partition { |guild| configured.include?(guild.id) }

    render Views::Servers::Index.new(
      present:,
      absent:,
      plugin_counts: PluginActivation.enabled_counts_for(configured),
      user: current_user
    )
  end

  def show
    render Views::Servers::Show.new(
      guild: @guild,
      server_configuration: @server_configuration,
      plugins: PluginStatus.rows(@server_configuration),
      user: current_user,
      servers: @configured_guilds,
      plugin_counts: @plugin_counts
    )
  end

  private

  def load_dashboard
    result = ServerDashboard.resolve(
      discord_token: session[:discord_token],
      target_id: params[:id].to_i,
      cached_ids: manageable_server_ids
    )
    return redirect_to(servers_path, alert: t("servers.not_found")) unless result

    remember_manageable_servers(result.configured_ids)
    @guild = result.guild
    @server_configuration = result.server_configuration
    @configured_guilds = result.configured_guilds
    @plugin_counts = result.plugin_counts
  end

  def reauthenticate
    return render_error if session[:reauth_attempted]

    session[:reauth_attempted] = true
    render Views::Reauth.new
  end

  def render_error
    session.delete(:reauth_attempted)
    render Views::Servers::Index.new(present: [], absent: [], plugin_counts: {}, user: current_user, error: true)
  end
end
