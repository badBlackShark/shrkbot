# frozen_string_literal: true

class Servers::RemindersController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin

  def show
    render Views::Servers::Reminders::Show.new(
      server_configuration: @server_configuration,
      user: current_user
    )
  end

  def update
    result = Ops::Reminders::Settings::Update.call(
      server_configuration: @server_configuration,
      force_dm_reminders: reminders_params[:force_dm_reminders]
    )
    @toast = {level: "notice", message: t("servers.reminders.saved")} if result.success?

    respond_to do |format|
      format.turbo_stream { render status: result.success? ? :ok : :unprocessable_content }
      format.html { redirect_to server_reminders_path(params[:server_id]), **flash_for(result) }
    end
  end

  private

  def reminders_params
    params.expect(reminders: [:force_dm_reminders])
  end
end
