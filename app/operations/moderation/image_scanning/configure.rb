# frozen_string_literal: true

module Ops
  module Moderation
    module ImageScanning
      class Configure < ApplicationOperation
        include Ops::PluginConfiguration
        include Ops::Moderation::SubPluginConfiguration

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
          activation = staged_activation

          return staff_role_guard_failure(activation) if enabling? && staff_role_missing?
          return failure(messages(settings, activation), value: activation) unless settings.valid? && activation.valid?

          settings.save!
          save_activation!(activation)
          ok(activation)
        end

        private

        def plugin_key
          :image_scanning
        end
      end
    end
  end
end
