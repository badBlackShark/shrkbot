class ServersController < ApplicationController
  before_action :require_login
  before_action :load_dashboard, only: :show
  before_action :authorize_mutation, only: [:update, :toggle_plugin]

  PluginRow = Data.define(:key, :enabled, :configured)

  def index
    manageable = manageable_guilds
    session.delete(:reauth_attempted)
    configured = configured_ids(manageable)
    remember_authorized(configured)
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
    toggle = Components::Toggle.new(
      name: :force_dm_reminders,
      checked: @server_configuration.reload.force_dm_reminders,
      label: t("views.servers.show.force_dm_title"),
      url: server_path(params[:id]),
      submit_on_change: true,
      dom_id: "force-dm-toggle"
    )
    save_response(
      [replace("force-dm-toggle", toggle), append_toast("notice", t("servers.saved"))]
    )
  end

  def toggle_plugin
    plugin = Plugin.find_by(key: params[:key])
    return save_response([append_toast("alert", t("servers.unknown_plugin"))]) unless plugin

    enabled = boolean(params[:enabled])
    result = Ops::ServerConfiguration::Plugins::Toggle.call(
      server_configuration: @server_configuration,
      plugin:,
      enabled:
    )

    save_response([replace_plugin_row(plugin), append_toast(*plugin_feedback(result, plugin, enabled))])
  end

  private

  def plugin_feedback(result, plugin, enabled)
    return ["alert", result.errors.to_sentence] if result.failure?

    ["notice", t(enabled ? "servers.plugin_enabled" : "servers.plugin_disabled", plugin: plugin.name)]
  end

  def replace_plugin_row(plugin)
    row = plugin_row_for(plugin)
    replace("plugin-#{plugin.key}", Components::PluginRow.new(server_id: params[:id], key: row.key, enabled: row.enabled, configured: row.configured))
  end

  def replace(target, component)
    turbo_stream.replace(target, render_to_string(component, layout: false))
  end

  def append_toast(level, message)
    turbo_stream.append("toasts", render_to_string(Components::Toast.new(level:, message:), layout: false))
  end

  def save_response(streams)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: streams }
      format.html { redirect_to server_path(params[:id]) }
    end
  end

  def load_dashboard
    manageable = manageable_guilds
    @guild = manageable.find { |guild| guild.id == params[:id].to_i }
    @server_configuration = ServerConfiguration.find_by(discord_id: params[:id]) if @guild
    return redirect_to(servers_path, alert: t("servers.not_found")) unless @guild && @server_configuration

    configured = configured_ids(manageable)
    remember_authorized(configured)
    @configured_guilds = manageable.select { |guild| configured.include?(guild.id) }
    @plugin_counts = enabled_plugin_counts(configured)
  rescue Discord::UserGuilds::Unauthorized
    redirect_to servers_path
  rescue Discord::UserGuilds::Error
    redirect_to servers_path, alert: t("servers.discord_error")
  end

  # Mutations authorize against the set of servers the user proved they manage
  # the last time they loaded the picker or a dashboard, so a toggle never
  # re-hits Discord's heavily rate-limited guild-list endpoint.
  def authorize_mutation
    @server_configuration = ServerConfiguration.find_by(discord_id: params[:id])
    return if @server_configuration && authorized_server_ids.include?(params[:id].to_i)

    redirect_to servers_path, alert: t("servers.not_found")
  end

  def remember_authorized(discord_ids)
    session[:authorized_server_ids] = discord_ids
  end

  def authorized_server_ids
    Array(session[:authorized_server_ids])
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

  def plugin_row_for(plugin)
    activation = @server_configuration.plugin_activations.find_by(plugin:)
    PluginRow.new(
      key: plugin.key,
      enabled: activation&.enabled? || false,
      configured: PluginCatalog.find(plugin.key).prerequisites_met?(@server_configuration)
    )
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
