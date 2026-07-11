# frozen_string_literal: true

class Servers::LoggingController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin

  def show
    render Views::Servers::Logging::Show.new(
      server_configuration: @server_configuration,
      user: current_user,
      enabled: plugin_enabled?
    )
  end

  def update
    result = Ops::Logging::Configure.call(
      server_configuration: @server_configuration,
      channel_id: logging_params[:channel_id],
      enabled_actions: submitted_actions,
      enabled: logging_params[:enabled]
    )
    respond_with_configuration(result)
  end

  private

  def submitted_actions
    raw = logging_params[:actions] || {}
    LoggableEventCatalog.all.to_h { |definition| [definition.key, ActiveModel::Type::Boolean.new.cast(raw[definition.key])] }
  end

  def logging_params
    params.require(:logging).permit(:channel_id, :enabled, actions: {})
  end
end
