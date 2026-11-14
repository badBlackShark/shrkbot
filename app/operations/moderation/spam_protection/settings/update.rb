# frozen_string_literal: true

module Ops
  module Moderation
    module SpamProtection
      module Settings
        class Update < ApplicationOperation
          include Ops::PluginConfiguration

          receives :server_configuration,
            :channel_threshold,
            :window_seconds,
            :similarity,
            :match_symbol_only_messages,
            :action,
            :punishment,
            :timeout_seconds,
            :enabled

          def call
            settings = server_configuration.spam_protection_settings
            settings.assign_attributes(
              channel_threshold:,
              window_seconds:,
              similarity:,
              match_symbol_only_messages:,
              action:,
              punishment:,
              timeout_seconds:
            )
            save_with_activation(settings)
          end

          private

          def plugin_key
            :spam_protection
          end
        end
      end
    end
  end
end
