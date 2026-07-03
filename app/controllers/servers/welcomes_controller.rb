# frozen_string_literal: true

class Servers::WelcomesController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin

  def show
    render Views::Servers::Welcomes::Show.new(
      server_configuration: @server_configuration,
      user: current_user,
      enabled: plugin_enabled?
    )
  end

  def update
    result = Ops::Welcomes::Configure.call(
      server_configuration: @server_configuration,
      channel_id: welcomes_params[:channel_id],
      join_message: welcomes_params[:join_message],
      leave_message: welcomes_params[:leave_message],
      enabled: welcomes_params[:enabled]
    )
    activation = result.value
    @enabled = activation.enabled?
    @enable_error = activation.errors[:enabled].first
    @toast = {level: "notice", message: t("servers.welcomes.saved")} if result.success?

    respond_to do |format|
      format.turbo_stream { render status: result.success? ? :ok : :unprocessable_content }
      format.html { redirect_to server_welcomes_path(params[:server_id]), **flash_for(result) }
    end
  end

  private

  def welcomes_params
    params.expect(welcomes: [:channel_id, :join_message, :leave_message, :enabled])
  end
end
