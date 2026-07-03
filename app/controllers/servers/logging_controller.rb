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
    activation = result.value
    @enabled = activation.enabled?
    @enable_error = activation.errors[:enabled].first
    @toast = {level: "notice", message: t("servers.logging.saved")} if result.success?

    respond_to do |format|
      format.turbo_stream { render status: result.success? ? :ok : :unprocessable_content }
      format.html { redirect_to server_logging_path(params[:server_id]), **flash_for(result) }
    end
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
