# frozen_string_literal: true

module Moderation
  class OverviewContext
    SubPluginRow = Data.define(:key, :name, :description, :enabled, :configured, :toggle_fields)

    SUB_PLUGINS = [
      {key: :spam_protection, settings_method: :spam_protection_settings, fields_method: :spam_protection_fields},
      {key: :image_scanning, settings_method: :image_scanning_settings, fields_method: :image_scanning_fields}
    ].freeze

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

    def sub_plugin_rows
      SUB_PLUGINS.map do |sub|
        key = sub[:key]
        definition = PluginCatalog.find(key)
        settings = @config.public_send(sub[:settings_method])
        SubPluginRow.new(
          key:,
          name: definition.name,
          description: definition.description,
          enabled: enabled_keys.include?(key),
          configured: definition.prerequisites_met?(@config, enabled_keys:),
          toggle_fields: settings ? send(sub[:fields_method], settings) : {}
        )
      end
    end

    def logging_channel_name
      return unless @config.logging_settings&.channel_id

      @config.server_channels.find_by(discord_id: @config.logging_settings.channel_id)&.name
    end

    private

    def enabled_keys
      @enabled_keys ||= @config.enabled_plugin_keys
    end

    def spam_protection_fields(settings)
      {
        "spam_protection[channel_threshold]" => settings.channel_threshold,
        "spam_protection[window_seconds]" => settings.window_seconds,
        "spam_protection[similarity]" => settings.similarity,
        "spam_protection[match_symbol_only_messages]" => settings.match_symbol_only_messages ? "1" : "0",
        "spam_protection[action]" => settings.action,
        "spam_protection[punishment]" => settings.punishment,
        "spam_protection[timeout_seconds]" => settings.timeout_seconds
      }
    end

    def image_scanning_fields(settings)
      {
        "image_scanning[sensitivity]" => settings.sensitivity,
        "image_scanning[action]" => settings.action,
        "image_scanning[punishment]" => settings.punishment,
        "image_scanning[timeout_seconds]" => settings.timeout_seconds,
        "image_scanning[confirmed_punishment]" => settings.confirmed_punishment,
        "image_scanning[confirmed_timeout_seconds]" => settings.confirmed_timeout_seconds,
        "image_scanning[custom_keyword_min_hits]" => settings.custom_keyword_min_hits,
        "image_scanning[custom_keywords][]" => settings.custom_keywords
      }
    end
  end
end
