# frozen_string_literal: true

module Ops
  module Moderation
    module SubPluginConfiguration
      private

      def staff_role_missing?
        server_configuration.moderation_settings&.staff_role_id.blank?
      end

      def staff_role_guard_failure(activation)
        activation.errors.add(:enabled, I18n.t("operations.moderation.staff_role_required"))
        failure(activation.errors[:enabled], value: activation)
      end
    end
  end
end
