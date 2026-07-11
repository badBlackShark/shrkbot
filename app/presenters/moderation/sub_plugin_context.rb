# frozen_string_literal: true

module Moderation
  class SubPluginContext
    def initialize(server_configuration, plugin_key)
      @config = server_configuration
      @plugin_key = plugin_key
    end

    def group_enabled?
      enabled_keys.include?(:moderation)
    end

    def staff_role_present?
      @config.moderation_settings&.staff_role_id.present?
    end

    def plugin_enabled?
      enabled_keys.include?(@plugin_key)
    end

    def settings
      if @plugin_key == :spam_protection
        @config.spam_protection_settings
      else
        @config.image_scanning_settings
      end
    end

    private

    def enabled_keys
      @enabled_keys ||= @config.enabled_plugin_keys
    end
  end
end
