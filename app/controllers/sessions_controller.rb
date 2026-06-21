class SessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]
    user = User.from_omniauth(auth)
    session[:user_id] = user.id
    session[:discord_token] = auth.credentials.token
    redirect_to servers_path, notice: "Signed in as #{user.username}."
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out."
  end

  def failure
    redirect_to root_path, alert: "Sign-in failed or was cancelled."
  end
end
