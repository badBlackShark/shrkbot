class ServersController < ApplicationController
  before_action :require_login
  before_action :load_server, only: [:show, :update, :toggle_plugin]

  PluginRow = Data.define(:key, :enabled, :configured)

  def index
    manageable = manageable_guilds
    session.delete(:reauth_attempted)
    configured_ids = configured_ids(manageable)
    present, absent = manageable.partition { |guild| configured_ids.include?(guild.id) }

    render Views::Servers::Index.new(
      present:,
      absent:,
      plugin_counts: enabled_plugin_counts(configured_ids),
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
      plugins: plugin_rows,
      user: current_user,
      servers: @configured_guilds,
      plugin_counts: @plugin_counts
    )
  end

  def update
    Ops::ServerConfiguration::Update.call(
      server_configuration: @server_configuration,
      force_dm_reminders: boolean(params[:force_dm_reminders])
    )
    redirect_to server_path(@guild.id), notice: t("servers.saved")
  end

  def toggle_plugin
    plugin = Plugin.find_by(key: params[:key])
    return redirect_to(server_path(@guild.id), alert: t("servers.unknown_plugin")) unless plugin

    enabled = boolean(params[:enabled])
    result = Ops::ServerConfiguration::Plugins::Toggle.call(
      server_configuration: @server_configuration,
      plugin:,
      enabled:
    )

    if result.success?
      key = enabled ? "servers.plugin_enabled" : "servers.plugin_disabled"
      redirect_to server_path(@guild.id), notice: t(key, plugin: plugin.name)
    else
      redirect_to server_path(@guild.id), alert: result.errors.to_sentence
    end
  end

  private

  def load_server
    manageable = manageable_guilds
    @guild = manageable.find { |guild| guild.id == params[:id].to_i }
    @server_configuration = ServerConfiguration.find_by(discord_id: params[:id]) if @guild
    return redirect_to(servers_path, alert: t("servers.not_found")) unless @guild && @server_configuration

    configured_ids = configured_ids(manageable)
    @configured_guilds = manageable.select { |guild| configured_ids.include?(guild.id) }
    @plugin_counts = enabled_plugin_counts(configured_ids)
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

  def plugin_rows
    activations = @server_configuration.plugin_activations.includes(:plugin).index_by { |activation| activation.plugin.key }
    PluginCatalog.all.map do |definition|
      PluginRow.new(
        key: definition.key,
        enabled: activations[definition.key]&.enabled? || false,
        configured: definition.prerequisites_met?(@server_configuration)
      )
    end
  end

  def enabled_plugin_counts(discord_ids)
    PluginActivation
      .joins(:server_configuration)
      .where(server_configurations: {discord_id: discord_ids}, enabled: true)
      .group("server_configurations.discord_id")
      .count
  end

  def boolean(value)
    ActiveModel::Type::Boolean.new.cast(value)
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
