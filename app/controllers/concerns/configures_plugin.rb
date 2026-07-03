# frozen_string_literal: true

module ConfiguresPlugin
  extend ActiveSupport::Concern

  private

  def plugin_enabled?
    @server_configuration.plugins.enabled.exists?(key: controller_name)
  end

  def flash_for(result)
    return {notice: t("servers.#{controller_name}.saved")} if result.success?

    {alert: result.errors.to_sentence}
  end
end
