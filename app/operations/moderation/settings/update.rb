# frozen_string_literal: true

module Ops
  module Moderation
    module Settings
      class Update < ApplicationOperation
        include Ops::PluginConfiguration

        receives :server_configuration, :staff_role_id, :enabled, :ping_staff, :new_account_age_days

        def call
          settings = server_configuration.moderation_settings
          settings.assign_attributes(staff_role_id: staff_role_id.presence)
          settings.ping_staff = ping_staff unless ping_staff.nil?
          settings.new_account_age_days = new_account_age_days if new_account_age_days.present?
          save_with_activation(settings)
        end

        private

        def plugin_key
          :moderation
        end
      end
    end
  end
end
