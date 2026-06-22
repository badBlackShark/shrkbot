class ServersController < ApplicationController
  before_action :require_login

  def index
    manageable = Discord::UserGuilds.call(session[:discord_token])
      .select(&:manageable?)
      .sort_by { |guild| -guild.member_count.to_i }
    session.delete(:reauth_attempted)
    configured_ids = ServerConfiguration.where(discord_id: manageable.map(&:id)).pluck(:discord_id)
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

  private

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
