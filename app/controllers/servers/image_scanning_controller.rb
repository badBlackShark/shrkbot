# frozen_string_literal: true

class Servers::ImageScanningController < ApplicationController
  include RequiresManageableServer
  include ConfiguresPlugin

  before_action :build_context

  def show
    render Views::Servers::ImageScanning::Show.new(
      server_configuration: @server_configuration,
      user: current_user,
      context: @context
    )
  end

  def update
    result = Ops::Moderation::ImageScanning::Configure.call(
      server_configuration: @server_configuration,
      sensitivity: image_scanning_params[:sensitivity],
      action: image_scanning_params[:action],
      punishment: image_scanning_params[:punishment],
      timeout_seconds: image_scanning_params[:timeout_seconds],
      custom_keyword_min_hits: image_scanning_params[:custom_keyword_min_hits],
      custom_keywords: image_scanning_params[:custom_keywords],
      enabled: image_scanning_params[:enabled]
    )
    activation = result.value
    @enabled = activation.enabled?
    @enable_error = activation.errors[:enabled].first
    @toast = {level: "notice", message: t("servers.image_scanning.saved")} if result.success?
    return redirect_to server_moderation_path(params[:server_id]), status: :see_other, **flash_for(result) if params[:from_overview]

    respond_to do |format|
      format.turbo_stream { render status: result.success? ? :ok : :unprocessable_content }
      format.html { redirect_to server_image_scanning_path(params[:server_id]), **flash_for(result) }
    end
  end

  private

  def image_scanning_params
    params.expect(
      image_scanning: [
        :sensitivity,
        :action,
        :punishment,
        :timeout_seconds,
        :custom_keyword_min_hits,
        :enabled,
        custom_keywords: []
      ]
    )
  end

  def build_context
    @context = Moderation::SubPluginContext.new(@server_configuration, :image_scanning)
  end
end
