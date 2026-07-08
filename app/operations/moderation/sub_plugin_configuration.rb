# frozen_string_literal: true

module Ops
  module Moderation
    module SubPluginConfiguration
      private

      def staff_role_missing?
        server_configuration.moderation_settings&.staff_role_id.blank?
      end

      def staff_role_guard_failure(activation)
        activation.errors.add(:enabled, "requires a staff role set on the Server Shield overview")
        failure(activation.errors[:enabled], value: activation)
      end
    end
  end
end
