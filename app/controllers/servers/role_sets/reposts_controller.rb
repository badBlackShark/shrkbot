# frozen_string_literal: true

class Servers::RoleSets::RepostsController < ApplicationController
  include RequiresManageableServer

  def create
    role_set = @server_configuration.role_setting.role_sets.find(params[:role_set_id])
    if roles_enabled?
      ConfigBus.repost_roles(role_set)
      @toast = {level: "notice", message: t("servers.role_sets.reposts.queued")}
      status = :ok
      flash_args = {notice: @toast[:message]}
    else
      @toast = {level: "alert", message: t("servers.role_sets.reposts.disabled")}
      status = :unprocessable_content
      flash_args = {alert: @toast[:message]}
    end

    respond_to do |format|
      format.turbo_stream { render status: }
      format.html { redirect_to server_roles_path(params[:server_id]), **flash_args }
    end
  end

  private

  def roles_enabled?
    @server_configuration.plugins.enabled.exists?(key: "roles")
  end
end
