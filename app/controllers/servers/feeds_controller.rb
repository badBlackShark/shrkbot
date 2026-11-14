# frozen_string_literal: true

class Servers::FeedsController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin
  include ReadsFeedPluginKey

  def show
    render Views::Servers::Feeds::Show.new(
      plugin_key:,
      server_configuration: @server_configuration,
      user: current_user
    )
  end

  def update
    result = toggle_plugin(toggle_params[:enabled])
    respond_with_configuration(result)
  end

  private

  def toggle_params
    params.expect(plugin_key => [:enabled])
  end

  def configuration_url
    PluginPaths.for(@server_configuration, plugin_key)
  end
end
