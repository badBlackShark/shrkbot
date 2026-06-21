class ServersController < ApplicationController
  before_action :require_login

  def index
    manageable = Discord::UserGuilds.call(session[:discord_token]).select(&:manageable?)
    session.delete(:reauth_attempted)
    configured_ids = ServerConfiguration.where(discord_id: manageable.map(&:id)).pluck(:discord_id)
    present, absent = manageable.partition { |guild| configured_ids.include?(guild.id) }

    render Views::Servers::Index.new(present:, absent:)
  rescue Discord::UserGuilds::Unauthorized
    reauthenticate
  rescue Discord::UserGuilds::Error
    render_error
  end

  private

  def reauthenticate
    return render_error if session[:reauth_attempted]

    session[:reauth_attempted] = true
    render Views::Reauth.new
  end

  def render_error
    session.delete(:reauth_attempted)
    render Views::Servers::Index.new(present: [], absent: [], error: true)
  end
end
