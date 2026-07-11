# frozen_string_literal: true

class PluginCatalog
  Definition = Data.define(:key, :name, :description, :channel_setting, :requires_plugin, :parent, :prerequisite) do
    def initialize(key:, name:, description:, channel_setting: nil, requires_plugin: nil, parent: nil, prerequisite: nil)
      super
    end

    def channel_backed?
      !channel_setting.nil?
    end

    def prerequisites_met?(server_configuration, enabled_keys: nil)
      return false unless required_plugins_enabled?(server_configuration, enabled_keys)
      return false unless channel_met?(server_configuration)
      return false unless prerequisite.nil? || prerequisite.call(server_configuration)

      true
    end

    private

    def required_plugins_enabled?(server_configuration, enabled_keys)
      required = [requires_plugin, parent].compact
      return true if required.empty?

      keys = enabled_keys || server_configuration.enabled_plugin_keys
      required.all? { |key| keys.include?(key) }
    end

    def channel_met?(server_configuration)
      return true unless channel_backed?

      server_configuration.public_send(channel_setting)&.channel_id.present?
    end
  end

  DEFINITIONS = [
    Definition.new(key: :logging, name: "Logging", description: "Writes moderation actions to a log channel.", channel_setting: :logging_setting),
    Definition.new(key: :roles, name: "Roles", description: "Self-assignable roles.", channel_setting: :role_setting),
    Definition.new(key: :welcomes, name: "Welcomes", description: "Join and leave messages.", channel_setting: :welcome_settings),
    Definition.new(key: :moderation, name: "Server Shield", description: "Your server's aegis: automated moderation beyond Discord's AutoMod.", requires_plugin: :logging, prerequisite: ->(c) { c.logging_setting&.channel_id.present? }),
    Definition.new(key: :spam_protection, name: "Cross-Channel Spam Guard", description: "Detects the same message blasted across multiple channels within seconds and purges it before it spreads. Matching is fingerprint-based — message content is never stored.", parent: :moderation, prerequisite: ->(c) { c.moderation_settings&.staff_role_id.present? }),
    Definition.new(key: :image_scanning, name: "Scam Image Detection", description: "Reads the text inside posted images and checks it against known scam patterns and previously confirmed scam images. Staff confirm or dismiss every catch, and the bot remembers.", parent: :moderation, prerequisite: ->(c) { c.moderation_settings&.staff_role_id.present? })
  ].freeze

  def self.all
    DEFINITIONS
  end

  def self.find(key)
    DEFINITIONS.find { |definition| definition.key == key }
  end

  def self.channel_backed
    DEFINITIONS.select(&:channel_backed?)
  end

  def self.sub_plugin?(key)
    find(key)&.parent.present?
  end

  def self.sub_plugin_keys(parent_key)
    all.select { |definition| definition.parent == parent_key }.map(&:key)
  end
end
