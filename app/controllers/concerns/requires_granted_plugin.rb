# frozen_string_literal: true

module RequiresGrantedPlugin
  extend ActiveSupport::Concern

  included do
    before_action :require_granted_plugin
  end

  private

  def require_granted_plugin
    return if BespokePluginGrant.granted_keys(@server_configuration).include?(plugin_key)

    redirect_to server_path(@server_configuration.discord_id), alert: t("servers.unknown_plugin")
  end
end
