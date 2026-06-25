# frozen_string_literal: true

class PluginCatalog
  Definition = Data.define(:key, :name, :description, :channel_setting) do
    def channel_backed?
      !channel_setting.nil?
    end

    def prerequisites_met?(server_configuration)
      return true unless channel_backed?

      server_configuration.public_send(channel_setting)&.channel_id.present?
    end
  end

  DEFINITIONS = [
    Definition.new(key: :logging, name: "Logging", description: "Writes moderation actions to a log channel.", channel_setting: :logging_setting),
    Definition.new(key: :roles, name: "Roles", description: "Self-assignable roles.", channel_setting: :role_setting),
    Definition.new(key: :welcomes, name: "Welcomes", description: "Join and leave messages.", channel_setting: :welcome_settings)
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
end
