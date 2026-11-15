# frozen_string_literal: true

module Ops
  module Moderation
    module ImageScanning
      module Settings
        class Update < ApplicationOperation
          include Ops::PluginConfiguration

          receives :server_configuration,
            :sensitivity,
            :action,
            :punishment,
            :timeout_seconds,
            :confirmed_punishment,
            :confirmed_timeout_seconds,
            :custom_keywords,
            :custom_keyword_min_hits,
            :enabled

          def call
            settings = server_configuration.image_scanning_settings
            settings.assign_attributes(
              sensitivity:,
              action:,
              punishment:,
              timeout_seconds:,
              confirmed_punishment:,
              confirmed_timeout_seconds:,
              custom_keyword_min_hits:,
              custom_keywords: Array(custom_keywords).reject(&:blank?)
            )
            save_with_activation(settings)
          end

          private

          def plugin_key
            :image_scanning
          end
        end
      end
    end
  end
end
