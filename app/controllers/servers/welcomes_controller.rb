# frozen_string_literal: true

class Servers::WelcomesController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin
  include VerifiesGuildChannels

  def show
    render Views::Servers::Welcomes::Show.new(
      server_configuration: @server_configuration,
      user: current_user,
      enabled: plugin_enabled?
    )
  end

  def update
    return head :not_found unless guild_channels?(welcomes_params[:channel_id])

    result = Ops::Welcomes::Configure.call(
      server_configuration: @server_configuration,
      channel_id: welcomes_params[:channel_id],
      join_message: welcomes_params[:join_message],
      leave_message: welcomes_params[:leave_message],
      ping_on_join: welcomes_params.fetch(:ping_on_join, "1"),
      enabled: welcomes_params[:enabled]
    )
    respond_with_configuration(result)
  end

  private

  def welcomes_params
    params.expect(welcomes: [:channel_id, :join_message, :leave_message, :ping_on_join, :enabled])
  end
end
