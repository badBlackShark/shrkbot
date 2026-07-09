# frozen_string_literal: true

module Moderation
  class SubPluginContext
    def initialize(server_configuration, plugin_key)
      @config = server_configuration
      @plugin_key = plugin_key
    end

    def group_enabled?
      @config.plugins.enabled.exists?(key: :moderation)
    end

    def staff_role_present?
      @config.moderation_settings&.staff_role_id.present?
    end

    def plugin_enabled?
      @config.plugins.enabled.exists?(key: @plugin_key)
    end

    def settings
      if @plugin_key == :spam_protection
        @config.spam_protection_settings
      else
        @config.image_scanning_settings
      end
    end
  end
end
