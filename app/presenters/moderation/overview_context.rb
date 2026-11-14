# frozen_string_literal: true

module Moderation
  class OverviewContext
    def initialize(server_configuration)
      @config = server_configuration
    end

    def group_enabled?
      enabled_keys.include?(:moderation)
    end

    def logging_ready?
      enabled_keys.include?(:logging) &&
        @config.logging_settings&.channel_id.present?
    end

    def staff_role_id
      @config.moderation_settings&.staff_role_id
    end

    def ping_staff
      @config.moderation_settings&.ping_staff
    end

    def new_account_age_days
      @config.moderation_settings&.new_account_age_days
    end

    def staff_role_present?
      staff_role_id.present?
    end

    def permission_warning?
      # Mention-All-Roles detection lands here once bot permissions are stored
      false
    end

    def staff_permission_warning?
      return false unless staff_role_id

      role = @config.server_roles.find_by(discord_id: staff_role_id)
      role.present? && !role.manage_messages?
    end

    def logging_channel_name
      return unless @config.logging_settings&.channel_id

      @config.server_channels.find_by(discord_id: @config.logging_settings.channel_id)&.name
    end

    private

    def enabled_keys
      @enabled_keys ||= @config.enabled_plugin_keys
    end
  end
end
