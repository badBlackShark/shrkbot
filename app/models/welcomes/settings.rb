# frozen_string_literal: true

module Welcomes
  class Settings < ApplicationRecord
    self.table_name = "welcome_settings"

    attribute :join_message, default: -> { I18n.t("welcomes.default_message.join") }
    attribute :leave_message, default: -> { I18n.t("welcomes.default_message.leave") }

    belongs_to :server_configuration

    def self.active_for(discord_id)
      config = ServerConfiguration.find_by(discord_id:)
      return unless config&.plugins&.enabled&.exists?(key: :welcomes)

      config.welcome_settings
    end
  end
end
