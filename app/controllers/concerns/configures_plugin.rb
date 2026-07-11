# frozen_string_literal: true

module ConfiguresPlugin
  extend ActiveSupport::Concern

  private

  def plugin_enabled?
    @server_configuration.enabled_plugin_keys.include?(controller_name.to_sym)
  end

  def respond_with_configuration(result, error_keys: [:enabled])
    activation = result.value
    @enabled = activation.enabled?
    @enable_error = error_keys.filter_map { |key| activation.errors[key].first }.first
    @toast = {level: "notice", message: saved_message} if result.success?
    respond_to do |format|
      format.turbo_stream { render status: result.success? ? :ok : :unprocessable_content }
      format.html { redirect_to url_for(action: :show), **flash_for(result) }
    end
  end

  def flash_for(result)
    return {notice: saved_message} if result.success?

    {alert: result.errors.to_sentence}
  end

  def saved_message
    t("servers.#{controller_name}.saved")
  end
end
