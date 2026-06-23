class Servers::WelcomesController < ApplicationController
  include RequiresManageableServer

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
    activation = result.value
    @enabled = activation.enabled?
    @enable_error = activation.errors[:enabled].first
    @toast = {level: "notice", message: t("servers.welcomes.saved")} if result.success?

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to server_welcomes_path(params[:server_id]), **flash_for(result) }
    end
  end

  private

  def plugin_enabled?
    @server_configuration.plugins.enabled.exists?(key: :welcomes)
  end

  def welcomes_params
    params.expect(welcomes: [:channel_id, :join_message, :leave_message, :enabled])
  end

  def flash_for(result)
    return {notice: t("servers.welcomes.saved")} if result.success?

    {alert: result.errors.to_sentence}
  end
end
