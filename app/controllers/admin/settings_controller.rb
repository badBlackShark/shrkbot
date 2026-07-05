# frozen_string_literal: true

class Admin::SettingsController < ApplicationController
  before_action :require_owner

  def show
    render Views::Admin::Settings::Show.new(user: current_user)
  end

  def update
    result = Ops::BotSettings::Update.call(owner_error_dms: params[:owner_error_dms])
    @toast = {level: "notice", message: t(result.value ? "admin.settings.dms_enabled" : "admin.settings.dms_disabled")}

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to admin_settings_path }
    end
  end

  private

  def require_owner
    redirect_to servers_path, alert: t("admin.owner_only") unless current_user.owner?
  end
end
