# frozen_string_literal: true

class Servers::RemindersController < ApplicationController
  include RequiresManageableServer

  def show
    render Views::Servers::Reminders::Show.new(
      server_configuration: @server_configuration,
      user: current_user
    )
  end

  def update
    Ops::Reminders::Settings::Update.call(
      server_configuration: @server_configuration,
      force_dm_reminders: reminders_params[:force_dm_reminders]
    )
    @toast = {level: "notice", message: t("servers.reminders.saved")}

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to server_reminders_path(params[:server_id]), notice: @toast[:message] }
    end
  end

  private

  def reminders_params
    params.expect(reminders: [:force_dm_reminders])
  end
end
