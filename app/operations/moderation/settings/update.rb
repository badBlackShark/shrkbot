# frozen_string_literal: true

module Ops
  module Moderation
    module Settings
      class Update < ApplicationOperation
        receives :server_configuration, :staff_role_id, :ping_staff, :new_account_age_days

        def call
          settings = server_configuration.moderation_settings
          settings.assign_attributes(staff_role_id: staff_role_id.presence)
          settings.ping_staff = ping_staff unless ping_staff.nil?
          settings.new_account_age_days = new_account_age_days if new_account_age_days.present?
          return failure(settings.errors.full_messages) unless settings.valid?

          refusal = ::Ops::ServerConfiguration::Plugins::Toggle.dependent_refusal(:moderation, server_configuration)
          return failure(refusal) if refusal

          settings.save!
          ok(settings)
        end
      end
    end
  end
end
