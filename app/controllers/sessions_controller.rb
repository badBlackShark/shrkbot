class SessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]
    user = User.from_omniauth(auth)
    session[:user_id] = user.id
    session[:discord_token] = auth.credentials.token
    redirect_to servers_path, notice: t("sessions.signed_in", name: user.display_name)
  end

  def destroy
    reset_session
    redirect_to root_path, notice: t("sessions.signed_out")
  end

  def failure
    redirect_to root_path, alert: t("sessions.failed")
  end
end
