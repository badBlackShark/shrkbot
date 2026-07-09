# frozen_string_literal: true

class Servers::ModerationController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin

  before_action :build_context

  def show
    render Views::Servers::Moderation::Show.new(
      server_configuration: @server_configuration,
      user: current_user,
      context: @context
    )
  end

  def update
    result = Ops::Moderation::Configure.call(
      server_configuration: @server_configuration,
      staff_role_id: moderation_params[:staff_role_id],
      enabled: moderation_params[:enabled]
    )
    activation = result.value
    @enabled = activation.enabled?
    @enable_error = activation.errors[:enabled].first || activation.errors[:staff_role_id].first
    @toast = {level: "notice", message: t("servers.moderation.saved")} if result.success?

    respond_to do |format|
      format.turbo_stream { render status: result.success? ? :ok : :unprocessable_content }
      format.html { redirect_to server_moderation_path(params[:server_id]), **flash_for(result) }
    end
  end

  private

  def moderation_params
    params.expect(moderation: [:staff_role_id, :enabled])
  end

  def build_context
    @context = Moderation::OverviewContext.new(@server_configuration)
  end
end
