# frozen_string_literal: true

module Ops
  module Moderation
    class Configure < ApplicationOperation
      include Ops::PluginConfiguration

      receives :server_configuration, :staff_role_id, :enabled, :ping_staff, :new_account_age_days

      def call
        settings = server_configuration.moderation_settings
        settings.assign_attributes(staff_role_id: staff_role_id.presence)
        settings.ping_staff = ping_staff unless ping_staff.nil?
        settings.new_account_age_days = new_account_age_days if new_account_age_days.present?
        activation = staged_activation

        return logging_guard_failure(activation) if enabling? && !logging_ready?
        return staff_role_clear_failure(activation) if staff_role_id.blank? && sub_plugin_enabled?
        return account_age_failure(settings, activation) unless settings.valid?

        settings.save!
        activation.save!
        ok(activation)
      end

      private

      def logging_ready?
        server_configuration.plugins.enabled.exists?(key: :logging) &&
          server_configuration.logging_setting&.channel_id.present?
      end

      def sub_plugin_enabled?
        server_configuration.plugins.enabled.exists?(key: [:spam_protection, :image_scanning])
      end

      def logging_guard_failure(activation)
        activation.errors.add(:enabled, I18n.t("operations.moderation.logging_required"))
        failure(activation.errors[:enabled], value: activation)
      end

      def staff_role_clear_failure(activation)
        activation.errors.add(:staff_role_id, I18n.t("operations.moderation.staff_role_in_use"))
        failure(activation.errors[:staff_role_id], value: activation)
      end

      def account_age_failure(settings, activation)
        activation.errors.add(:new_account_age_days, settings.errors[:new_account_age_days].first)
        failure(activation.errors[:new_account_age_days], value: activation)
      end

      def plugin_key
        :moderation
      end
    end
  end
end
