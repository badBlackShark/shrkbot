# frozen_string_literal: true

class Servers::SteamController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin

  def show
    render Views::Servers::Steam::Show.new(
      server_configuration: @server_configuration,
      user: current_user
    )
  end

  def update
    result = toggle_plugin(steam_params[:enabled])
    respond_with_configuration(result)
  end

  private

  def steam_params
    params.expect(steam: [:enabled])
  end
end
