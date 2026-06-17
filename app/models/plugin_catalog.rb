class PluginCatalog
  # Single source for the plugin catalog: drives the db:seed catalog, the
  # enable-prerequisite gate (TogglePlugin + PluginActivation), and the
  # channel-backed registry consulted when a configured channel is deleted.
  Definition = Data.define(:key, :name, :description, :default_enabled, :channel_setting) do
    def channel_backed?
      !channel_setting.nil?
    end

    # A channel-backed plugin can't be enabled until its channel is set (#21).
    def prerequisites_met?(server_configuration)
      return true unless channel_backed?

      server_configuration.public_send(channel_setting)&.channel_id.present?
    end
  end

  DEFINITIONS = [
    Definition.new(key: :logging, name: "Logging", description: "Writes moderation actions to a log channel.", default_enabled: true, channel_setting: :logging_setting),
    Definition.new(key: :roles, name: "Roles", description: "Self-assignable roles.", default_enabled: false, channel_setting: :role_setting),
    Definition.new(key: :welcomes, name: "Welcomes", description: "Join and leave messages.", default_enabled: false, channel_setting: :welcome_settings)
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
