# frozen_string_literal: true

module Moderation
  class OverviewContext
    SubPluginRow = Data.define(:key, :name, :description, :enabled, :configured, :settings)

    SUB_PLUGINS = [
      {key: :spam_protection, settings_method: :spam_protection_settings},
      {key: :image_scanning, settings_method: :image_scanning_settings}
    ].freeze

    def initialize(server_configuration)
      @config = server_configuration
    end

    def group_enabled?
      @config.plugins.enabled.exists?(key: :moderation)
    end

    def logging_ready?
      @config.plugins.enabled.exists?(key: :logging) &&
        @config.logging_setting&.channel_id.present?
    end

    def staff_role_id
      @config.moderation_settings&.staff_role_id
    end

    def ping_staff
      @config.moderation_settings&.ping_staff
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

    def sub_plugin_rows
      SUB_PLUGINS.map do |sub|
        key = sub[:key]
        definition = PluginCatalog.find(key)
        settings = @config.public_send(sub[:settings_method])
        SubPluginRow.new(
          key:,
          name: definition.name,
          description: definition.description,
          enabled: @config.plugins.enabled.exists?(key:),
          configured: definition.prerequisites_met?(@config),
          settings:
        )
      end
    end

    def logging_channel_name
      return unless @config.logging_setting&.channel_id

      @config.server_channels.find_by(discord_id: @config.logging_setting.channel_id)&.name
    end
  end
end
