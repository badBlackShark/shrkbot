# frozen_string_literal: true

class Servers::TwitchController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin

  def show
    render Views::Servers::Twitch::Show.new(
      server_configuration: @server_configuration,
      user: current_user
    )
  end

  def update
    result = toggle_plugin(twitch_params[:enabled])
    return redirect_to_overview(result) if params[:from_overview]

    respond_with_configuration(result)
  end

  private

  def twitch_params
    params.expect(twitch: [:enabled])
  end
end
