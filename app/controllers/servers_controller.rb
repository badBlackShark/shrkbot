class ServersController < ApplicationController
  include ManageableServers

  before_action :require_login
  before_action :load_dashboard, only: :show

  def index
    manageable = manageable_guilds
    session.delete(:reauth_attempted)
    configured = configured_ids(manageable)
    remember_manageable_servers(configured)
    present, absent = manageable.partition { |guild| configured.include?(guild.id) }

    render Views::Servers::Index.new(
      present:,
      absent:,
      plugin_counts: enabled_plugin_counts(configured),
      user: current_user
    )
  rescue Discord::UserGuilds::Unauthorized
    reauthenticate
  rescue Discord::UserGuilds::Error
    render_error
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
    manageable = manageable_guilds
    @guild = manageable.find { |guild| guild.id == params[:id].to_i }
    @server_configuration = ServerConfiguration.find_by(discord_id: params[:id]) if @guild
    return redirect_to(servers_path, alert: t("servers.not_found")) unless @guild && @server_configuration

    configured = configured_ids(manageable)
    remember_manageable_servers(configured)
    @configured_guilds = manageable.select { |guild| configured.include?(guild.id) }
    @plugin_counts = enabled_plugin_counts(configured)
  rescue Discord::UserGuilds::Unauthorized
    redirect_to servers_path
  rescue Discord::UserGuilds::Error
    redirect_to servers_path, alert: t("servers.discord_error")
  end

  def manageable_guilds
    Discord::UserGuilds.call(session[:discord_token])
      .select(&:manageable?)
      .sort_by { |guild| -guild.member_count.to_i }
  end

  def configured_ids(guilds)
    ServerConfiguration.where(discord_id: guilds.map(&:id)).pluck(:discord_id)
  end

  def enabled_plugin_counts(discord_ids)
    PluginActivation
      .joins(:server_configuration)
      .where(server_configurations: {discord_id: discord_ids}, enabled: true)
      .group("server_configurations.discord_id")
      .count
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
