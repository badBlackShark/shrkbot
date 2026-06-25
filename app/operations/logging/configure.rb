# frozen_string_literal: true

module Ops
  module Logging
    class Configure < ApplicationOperation
      receives :server_configuration, :channel_id, :enabled_actions, :enabled

      def call
        settings = server_configuration.logging_setting
        settings.assign_attributes(channel_id: channel_id, enabled_actions: enabled_actions)
        activation = staged_activation

        return failure(messages(settings, activation), value: activation) unless settings.valid? && activation.valid?

        settings.save!
        activation.save!
        ok(activation)
      end

      private

      def staged_activation
        activation = server_configuration.plugin_activations.find_or_initialize_by(plugin: Plugin.find_by!(key: :logging))
        activation.enabled = enabled
        activation
      end

      def messages(*records)
        records.flat_map { |record| record.errors.full_messages }
      end
    end
  end
end
