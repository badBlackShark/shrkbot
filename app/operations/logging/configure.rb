# frozen_string_literal: true

module Ops
  module Logging
    class Configure < ApplicationOperation
      include Ops::PluginConfiguration

      receives :server_configuration, :channel_id, :enabled_actions, :enabled

      def call
        settings = server_configuration.logging_setting
        settings.assign_attributes(channel_id:, enabled_actions:)
        activation = staged_activation

        return failure(messages(settings, activation), value: activation) unless settings.valid? && activation.valid?

        settings.save!
        activation.save!
        ok(activation)
      end

      private

      def plugin_key
        :logging
      end
    end
  end
end
