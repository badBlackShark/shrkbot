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

        return moderation_dependency_failure(activation) if moderation_enabled? && !logging_stays_available?
        return failure(messages(settings, activation), value: activation) unless settings.valid? && activation.valid?

        settings.save!
        save_activation!(activation)
        ok(activation)
      end

      private

      def moderation_enabled?
        server_configuration.plugins.enabled.exists?(key: :moderation)
      end

      def logging_stays_available?
        enabling? && channel_id.present?
      end

      def moderation_dependency_failure(activation)
        activation.errors.add(:enabled, I18n.t("operations.logging.moderation_dependency"))
        failure(activation.errors[:enabled], value: activation)
      end

      def plugin_key
        :logging
      end
    end
  end
end
