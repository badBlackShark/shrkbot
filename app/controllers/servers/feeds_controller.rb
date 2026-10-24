# frozen_string_literal: true

class Servers::FeedsController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin

  def show
    render Views::Servers::Feeds::Show.new(
      server_configuration: @server_configuration,
      user: current_user,
      enabled: plugin_enabled?
    )
  end

  def update
    result = toggle_plugin(feeds_params[:enabled])
    respond_with_configuration(result)
  end

  private

  def feeds_params
    params.expect(feeds: [:enabled])
  end
end
