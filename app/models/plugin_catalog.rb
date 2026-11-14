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

  Group = Data.define(:key, :name)

  NEW_FOR = 30.days

  DEFINITIONS = [
    Definition.new(key: :logging, name: "Logging", description: "Writes moderation actions to a log channel.", channel_setting: :logging_settings),
    Definition.new(key: :roles, name: "Roles", description: "Self-assignable roles.", channel_setting: :role_setting),
    Definition.new(key: :welcomes, name: "Welcomes", description: "Join and leave messages.", channel_setting: :welcome_settings),
    Definition.new(key: :spam_protection, name: "Cross-Channel Spam Guard", description: "Detects the same message blasted across multiple channels within seconds and purges it before it spreads. Matching is fingerprint-based — message content is never stored.", requires_plugin: :logging, parent: :moderation, prerequisite: ->(c) { c.moderation_settings&.staff_role_id.present? }),
    Definition.new(key: :image_scanning, name: "Scam Image Detection", description: "Reads the text inside posted images and checks it against known scam patterns and previously confirmed scam images. Staff confirm or dismiss every catch, and the bot remembers.", requires_plugin: :logging, parent: :moderation, prerequisite: ->(c) { c.moderation_settings&.staff_role_id.present? }),
    Definition.new(key: :lfg, name: "Looking for Game", description: "Let members find people to play with both on the fly and scheduled in the future. Only shrkbot will ping, allowing you to turn off generally available role pings."),
    Definition.new(key: :steam, name: "Steam", description: "Posts new patch notes, announcements, and press coverage of the Steam games you follow.", parent: :integrations),
    Definition.new(key: :twitch, name: "Twitch", description: "Announces when the Twitch channels you follow go live, and posts their highlights, uploads, and clips.", parent: :integrations, beta: true),
    Definition.new(key: :twilight_struggle, name: "Twilight Struggle", description: "Posts results from twilight-struggle.com as they are reported. Subscribe to a tournament, pick its channel, and write the message however you like.", bespoke: true)
  ].freeze

  GROUPS = [
    Group.new(key: :moderation, name: "Server Shield"),
    Group.new(key: :integrations, name: "Integrations")
  ].freeze

  GLOBAL_KEYS = [:reminders].freeze

  def self.all
    DEFINITIONS
  end

  def self.find(key)
    DEFINITIONS.find { |definition| definition.key == key }
  end

  def self.group(key)
    GROUPS.find { |group| group.key == key }
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

  def self.unmet_dependent(key, server_configuration, enabled_keys: server_configuration.enabled_plugin_keys)
    dependents_of(key).find do |dependent|
      enabled_keys.include?(dependent.key) && dependent.blockers(server_configuration, enabled_keys:).any?
    end
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
