# frozen_string_literal: true

class Views::Servers::SubPluginShow < Views::Servers::PluginConfigShow
  private

  def enabled?
    enabled_keys.include?(plugin_key)
  end

  def enabled_keys
    @enabled_keys ||= @config.enabled_plugin_keys
  end

  def gate
    nil
  end
end
