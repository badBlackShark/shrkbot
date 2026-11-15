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

    def blockers(server_configuration, enabled_keys: server_configuration.enabled_plugin_keys)
      [
        (:not_granted unless granted?(server_configuration)),
        (:requires_plugin unless required_plugin_ready?(server_configuration, enabled_keys)),
        (:channel_missing unless channel_met?(server_configuration)),
        (:prerequisite unless prerequisite_met?(server_configuration))
      ].compact
    end

    def prerequisites_met?(server_configuration, enabled_keys: server_configuration.enabled_plugin_keys)
      blockers(server_configuration, enabled_keys:).empty?
    end

    private

    def granted?(server_configuration)
      return true unless bespoke

      ::BespokePluginGrant.exists?(server_configuration:, plugin_key: key)
    end

    def required_plugin_ready?(server_configuration, enabled_keys)
      requires_plugin.nil? ||
        (enabled_keys.include?(requires_plugin) && PluginCatalog.find(requires_plugin).prerequisites_met?(server_configuration, enabled_keys:))
    end

    def prerequisite_met?(server_configuration)
      prerequisite.nil? || prerequisite.call(server_configuration)
    end

    def channel_met?(server_configuration)
      return true unless channel_backed?

      server_configuration.public_send(channel_setting)&.channel_id.present?
    end
  end

  Group = Data.define(:key, :name, :description)

  NEW_FOR = 30.days

  DEFINITIONS = [
    Definition.new(key: :logging, name: "Logging", description: "Records what's happening on your server.", channel_setting: :logging_settings),
    Definition.new(key: :roles, name: "Roles", description: "Let members give themselves roles from a menu.", channel_setting: :role_setting),
    Definition.new(key: :welcomes, name: "Welcomes", description: "Greet new members and say goodbye when they leave.", channel_setting: :welcome_settings),
    Definition.new(key: :spam_protection, name: "Cross-Channel Spam Guard", description: "Detects messages spammed across multiple channels without storing message content.", requires_plugin: :logging, parent: :moderation, prerequisite: ->(c) { c.moderation_settings&.staff_role_id.present? }),
    Definition.new(key: :image_scanning, name: "Scam Image Detection", description: "Reads the text inside posted images and checks it against known scam patterns and previously confirmed scam images.", requires_plugin: :logging, parent: :moderation, prerequisite: ->(c) { c.moderation_settings&.staff_role_id.present? }),
    Definition.new(key: :lfg, name: "Looking for Game", description: "Let members find people to play with, on the fly or scheduled."),
    Definition.new(key: :steam, name: "Steam", description: "Posts new patch notes, announcements, and press coverage of the Steam games you follow.", parent: :integrations),
    Definition.new(key: :twitch, name: "Twitch", description: "Announces when the Twitch channels you follow go live, and posts their highlights, uploads, and clips.", parent: :integrations, beta: true),
    Definition.new(key: :twilight_struggle, name: "Twilight Struggle", description: "Post results from twilight-struggle.com as they are reported.", bespoke: true)
  ].freeze

  GROUPS = [
    Group.new(key: :moderation, name: "Server Shield", description: "Automated moderation that goes further than Discord's AutoMod."),
    Group.new(key: :integrations, name: "Integrations", description: "Posts updates from other platforms to your server.")
  ].freeze

  GLOBALS = [
    Definition.new(key: :reminders, name: "Reminders", description: "Members set their own reminders with /remind.")
  ].freeze

  GLOBAL_KEYS = GLOBALS.map(&:key).freeze

  def self.all
    DEFINITIONS
  end

  def self.find(key)
    DEFINITIONS.find { |definition| definition.key == key }
  end

  def self.group(key)
    GROUPS.find { |group| group.key == key }
  end

  def self.group_keys
    GROUPS.map(&:key)
  end

  def self.group?(key)
    group_keys.include?(key.to_sym)
  end

  def self.description(key)
    [*DEFINITIONS, *GROUPS, *GLOBALS].find { |entry| entry.key == key }.description
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

  def self.dependents_of(key)
    all.select { |definition| definition.requires_plugin == key || definition.parent == key }
  end

  def self.dependents_broken_by(key, server_configuration, enabled_keys:)
    blocked = dependents_of(key)
      .select { |dependent| enabled_keys.include?(dependent.key) }
      .to_h { |dependent| [dependent, dependent.blockers(server_configuration, enabled_keys:)] }
      .reject { |_dependent, blockers| blockers.empty? }
    return [] if blocked.empty?

    saved = ::ServerConfiguration.find(server_configuration.id)
    saved_keys = saved.enabled_plugin_keys
    blocked.select { |dependent, blockers| (blockers - dependent.blockers(saved, enabled_keys: saved_keys)).any? }.keys
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
