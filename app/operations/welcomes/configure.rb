module Ops
  module Welcomes
    class Configure < ApplicationOperation
      receives :server_configuration, :channel_id, :join_message, :leave_message, :enabled

      def call
        settings = server_configuration.welcome_settings
        settings.assign_attributes(channel_id: channel_id, join_message: join_message, leave_message: leave_message)
        activation = staged_activation

        return failure(messages(settings, activation), value: activation) unless settings.valid? && activation.valid?

        settings.save!
        activation.save!
        ok(activation)
      end

      private

      def staged_activation
        activation = server_configuration.plugin_activations.find_or_initialize_by(plugin: Plugin.find_by!(key: :welcomes))
        activation.enabled = enabled
        activation
      end

      def messages(*records)
        records.flat_map { |record| record.errors.full_messages }
      end
    end
  end
end
