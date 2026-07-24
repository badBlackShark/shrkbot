# frozen_string_literal: true

module Ops
  module Welcomes
    class Configure < ApplicationOperation
      include Ops::PluginConfiguration

      receives :server_configuration, :channel_id, :join_message, :leave_message, :ping_on_join, :enabled

      def call
        settings = server_configuration.welcome_settings
        settings.assign_attributes(channel_id:, join_message:, leave_message:, ping_on_join:)
        activation = staged_activation

        return failure(messages(settings, activation), value: activation) unless settings.valid? && activation.valid?

        settings.save!
        save_activation!(activation)
        ok(activation)
      end

      private

      def plugin_key
        :welcomes
      end
    end
  end
end
