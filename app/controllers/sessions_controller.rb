# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :require_login

  def create
    auth = request.env["omniauth.auth"]
    user = User.from_omniauth(auth)
    destination = session.delete(:return_to) || servers_path
    session[:user_id] = user.id
    session[:discord_token] = auth.credentials.token
    session.delete(:reauth_attempted)
    redirect_to destination, notice: t("sessions.signed_in", name: user.display_name)
  end

  def destroy
    reset_session
    redirect_to root_path, notice: t("sessions.signed_out")
  end

  def failure
    redirect_to root_path, alert: t("sessions.failed")
  end
end
