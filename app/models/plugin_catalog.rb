# frozen_string_literal: true

class PluginCatalog
  Definition = Data.define(:key, :name, :description, :channel_setting, :requires_plugin, :parent, :prerequisite, :bespoke, :beta, :added_on) do
    def initialize(key:, name:, description:, channel_setting: nil, requires_plugin: nil, parent: nil, prerequisite: nil, bespoke: false, beta: false, added_on: nil)
      super
    end

    def recently_added?
      added_on.present? && Date.current < added_on + PluginCatalog::NEW_FOR
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

  NEW_FOR = 30.days

  DEFINITIONS = [
    Definition.new(key: :logging, name: "Logging", description: "Records what's happening on your server.", channel_setting: :logging_settings),
    Definition.new(key: :roles, name: "Roles", description: "Let members give themselves roles from a menu.", channel_setting: :role_setting),
    Definition.new(key: :welcomes, name: "Welcomes", description: "Greet new members and say goodbye when they leave.", channel_setting: :welcome_settings),
    Definition.new(key: :moderation, name: "Server Shield", description: "Automated moderation that goes further than Discord's AutoMod.", requires_plugin: :logging, prerequisite: ->(c) { c.logging_settings&.channel_id.present? }),
    Definition.new(key: :spam_protection, name: "Cross-Channel Spam Guard", description: "Detects messages spammed across multiple channels without storing message content.", parent: :moderation, prerequisite: ->(c) { c.moderation_settings&.staff_role_id.present? }),
    Definition.new(key: :image_scanning, name: "Scam Image Detection", description: "Reads the text inside posted images and checks it against known scam patterns and previously confirmed scam images.", parent: :moderation, prerequisite: ->(c) { c.moderation_settings&.staff_role_id.present? }),
    Definition.new(key: :lfg, name: "Looking for Game", description: "Let members find people to play with, on the fly or scheduled."),
    Definition.new(key: :integrations, name: "Integrations", description: "Posts updates from other platforms to your server."),
    Definition.new(key: :steam, name: "Steam", description: "Posts new patch notes, announcements, and press coverage of the Steam games you follow.", parent: :integrations),
    Definition.new(key: :twitch, name: "Twitch", description: "Announces when the Twitch channels you follow go live, and posts their highlights, uploads, and clips.", parent: :integrations, beta: true),
    Definition.new(key: :twilight_struggle, name: "Twilight Struggle", description: "Post results from twilight-struggle.com as they are reported.", bespoke: true)
  ].freeze

  GLOBALS = [
    Definition.new(key: :reminders, name: "Reminders", description: "Members set their own reminders with /remind. This plugin can't be disabled.")
  ].freeze

  GLOBAL_KEYS = GLOBALS.map(&:key).freeze

  def self.all
    DEFINITIONS
  end

  def self.find(key)
    DEFINITIONS.find { |definition| definition.key == key }
  end

  def self.description(key)
    [*DEFINITIONS, *GLOBALS].find { |definition| definition.key == key }.description
  end

  def self.recently_added?(key)
    [key, *sub_plugin_keys(key)].any? { |candidate| find(candidate)&.recently_added? }
  end

  def self.beta?(key)
    find(key)&.beta || false
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

  def self.visible_sub_plugin_keys(parent_key, server_configuration, visible: visible_for(server_configuration))
    visible.select { |definition| definition.parent == parent_key }.map(&:key)
  end
end
