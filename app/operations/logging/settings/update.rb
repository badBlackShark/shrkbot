# frozen_string_literal: true

module Ops
  module Logging
    module Settings
      class Update < ApplicationOperation
        receives :server_configuration, :channel_id

        def call
          return failure(I18n.t("operations.logging.channel_required")) if channel_id.blank?

          setting = server_configuration.logging_setting
          setting.update!(channel_id:)
          ok(setting, warnings: visibility_warnings)
        end

        private

        def visibility_warnings
          channel = server_configuration.server_channels.find_by(discord_id: channel_id)
          return [] unless channel&.everyone_visible?

          [I18n.t("operations.logging.channel_public_warning")]
        end
      end
    end
  end
end
