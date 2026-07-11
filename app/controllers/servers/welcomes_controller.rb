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
    respond_with_configuration(result)
  end

  private

  def welcomes_params
    params.expect(welcomes: [:channel_id, :join_message, :leave_message, :enabled])
  end
end
