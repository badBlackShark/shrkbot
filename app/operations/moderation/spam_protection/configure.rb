# frozen_string_literal: true

module Ops
  module Moderation
    module SpamProtection
      class Configure < ApplicationOperation
        include Ops::PluginConfiguration
        include Ops::Moderation::SubPluginConfiguration

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
          activation = staged_activation

          return staff_role_guard_failure(activation) if enabling? && staff_role_missing?
          return failure(messages(settings, activation), value: activation) unless settings.valid? && activation.valid?

          settings.save!
          activation.save!
          ok(activation)
        end

        private

        def plugin_key
          :spam_protection
        end
      end
    end
  end
end
