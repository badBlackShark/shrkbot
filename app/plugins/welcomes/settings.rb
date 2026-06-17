module Welcomes
  class Settings < ApplicationRecord
    self.table_name = "welcome_settings"

    belongs_to :server_configuration

    # The setting only if welcomes is enabled for that server — the runtime gate
    # for the (command-less) event handlers.
    def self.active_for(discord_id)
      config = ServerConfiguration.find_by(discord_id:)
      return unless config&.enabled_plugins&.exists?(key: :welcomes)

      config.welcome_settings
    end
  end
end
