# frozen_string_literal: true

module ConfiguresPlugin
  extend ActiveSupport::Concern

  private

  def require_toggle_access
    return if plugin_access.toggle?(plugin_key)

    redirect_to server_path(params[:server_id]), alert: t("servers.plugin_locked")
  end

  def plugin_enabled?
    @server_configuration.enabled_plugin_keys.include?(plugin_key)
  end

  def toggle_plugin(enabled)
    Ops::ServerConfiguration::Plugins::Toggle.call(
      server_configuration: @server_configuration,
      plugin: Plugin.find_by!(key: plugin_key.to_s),
      enabled:
    )
  end

  def respond_with_save(result)
    @save_error = save_error_message(result) if result.failure?
    @toast = result.success? ? {level: saved_level(result.value), message: saved_message(result.value)} : {level: "alert", message: @save_error}
    respond_to do |format|
      format.turbo_stream { render status: result.success? ? :ok : :unprocessable_content }
      format.html { redirect_to configuration_url, **flash_for(result) }
    end
  end

  def configuration_url
    url_for(action: :show)
  end

  def flash_for(result)
    return {flash: {saved_level(result.value) => saved_message(result.value)}} if result.success?

    {alert: save_error_message(result)}
  end

  def save_error_message(result)
    result.errors.to_sentence.presence || t("servers.save_failed")
  end

  def saved_level(saved)
    left_disabled?(saved) ? "warning" : "notice"
  end

  def saved_message(saved)
    return t("servers.saved_while_disabled", plugin: PluginCatalog.find(plugin_key).name) if left_disabled?(saved)

    t("servers.#{plugin_key}.saved")
  end

  def left_disabled?(saved)
    saved.is_a?(PluginActivation) && !saved.enabled? && !saved.saved_change_to_enabled?
  end
end
