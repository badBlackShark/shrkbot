# frozen_string_literal: true

class Servers::IntegrationsController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin

  def show
    render Views::Servers::Integrations::Show.new(
      server_configuration: @server_configuration,
      user: current_user,
      enabled: plugin_enabled?
    )
  end

  def update
    result = toggle_plugin(integrations_params[:enabled])
    respond_with_configuration(result)
  end

  private

  def integrations_params
    params.expect(integrations: [:enabled])
  end
end
