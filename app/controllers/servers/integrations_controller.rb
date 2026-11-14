# frozen_string_literal: true

class Servers::IntegrationsController < ApplicationController
  include RequiresManageableServer

  def show
    render Views::Servers::Integrations::Show.new(
      server_configuration: @server_configuration,
      user: current_user
    )
  end
end
