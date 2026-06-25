# frozen_string_literal: true

class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :require_login

  helper_method :current_user

  private

  def current_user
    User.find_by(id: session[:user_id])
  end

  def require_login
    redirect_to root_path, alert: t("authentication.login_required") unless current_user
  end
end
