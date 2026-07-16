# frozen_string_literal: true

module DiscordReauth
  extend ActiveSupport::Concern

  included do
    rescue_from Bot::Discord::UserGuilds::Unauthorized, with: :reauthenticate
  end

  private

  def reauthenticate
    if session[:reauth_attempted]
      reset_session
      return redirect_to(root_path, alert: t("sessions.reauth_failed"))
    end

    session[:reauth_attempted] = true
    session[:return_to] = replayable_request? ? request.fullpath : servers_path
    render Views::Reauth.new
  end

  def replayable_request?
    request.get? || request.head?
  end
end
