# frozen_string_literal: true

class PluginCatalog
  Definition = Data.define(:key, :name, :description, :channel_setting, :requires_plugin, :parent, :prerequisite, :bespoke) do
    def initialize(key:, name:, description:, channel_setting: nil, requires_plugin: nil, parent: nil, prerequisite: nil, bespoke: false)
      super
    end

    def channel_backed?
      !channel_setting.nil?
    end

    def prerequisites_met?(server_configuration, enabled_keys: nil)
      return false unless granted?(server_configuration)
      return false unless required_plugins_enabled?(server_configuration, enabled_keys)
      return false unless channel_met?(server_configuration)
      return false unless prerequisite.nil? || prerequisite.call(server_configuration)

      true
    end

    private

    def granted?(server_configuration)
      return true unless bespoke

      ::BespokePluginGrant.exists?(server_configuration:, plugin_key: key)
    end

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
    Definition.new(key: :image_scanning, name: "Scam Image Detection", description: "Reads the text inside posted images and checks it against known scam patterns and previously confirmed scam images. Staff confirm or dismiss every catch, and the bot remembers.", parent: :moderation, prerequisite: ->(c) { c.moderation_settings&.staff_role_id.present? }),
    Definition.new(key: :lfg, name: "Looking for Game", description: "Let members find people to play with both on the fly and scheduled in the future. Only shrkbot will ping, allowing you to turn off generally available role pings."),
    Definition.new(key: :twilight_struggle, name: "Twilight Struggle", description: "Posts results from twilight-struggle.com as they are reported. Claim a tournament, pick its channel, and write the message however you like.", bespoke: true)
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

  def self.bespoke
    DEFINITIONS.select(&:bespoke)
  end

  def self.visible_for(server_configuration)
    granted = BespokePluginGrant.granted_keys(server_configuration)
    DEFINITIONS.reject { |definition| definition.bespoke && !granted.include?(definition.key) }
  end

  def self.sub_plugin?(key)
    find(key)&.parent.present?
  end

  def self.sub_plugin_keys(parent_key)
    all.select { |definition| definition.parent == parent_key }.map(&:key)
  end
end
