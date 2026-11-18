# frozen_string_literal: true

module Ops
  module Lfg
    module Settings
      class Update < ApplicationOperation
        include Ops::PluginConfiguration

        self.transactional = false

        receives :server_configuration,
          :enabled,
          :cooldown_seconds,
          :post_lifetime_minutes,
          :default_min_membership_days,
          :default_required_role_ids,
          :default_excluded_role_ids,
          :allowed_channel_ids,
          :pingable_roles

        def call
          error = card_error
          return failure(error) if error

          settings = server_configuration.lfg_settings
          settings.assign_attributes(
            cooldown_seconds:,
            post_lifetime_minutes:,
            default_min_membership_days: default_min_membership_days.presence,
            default_required_role_ids:,
            default_excluded_role_ids:,
            allowed_channel_ids:
          )
          save_with_activation(settings) { reconcile_pingable_roles(settings) }
        end

        private

        def reconcile_pingable_roles(settings)
          kept = pingable_roles.map do |attrs|
            role_id = role_id_of(attrs)
            role = settings.pingable_roles.find_or_initialize_by(role_id:)
            role.assign_attributes(
              min_membership_days: attrs[:min_membership_days].presence,
              required_role_ids: attrs[:required_role_ids],
              excluded_role_ids: attrs[:excluded_role_ids],
              allowed_channel_ids: attrs[:allowed_channel_ids]
            )
            role.save!
            role_id
          end
          settings.pingable_roles.where.not(role_id: kept).destroy_all
        end

        def card_error
          role_ids = pingable_roles.map { |attrs| role_id_of(attrs) }
          return I18n.t("operations.lfg.settings.role_required") if role_ids.include?(0)

          I18n.t("operations.lfg.settings.duplicate_role") if role_ids.uniq.size != role_ids.size
        end

        def role_id_of(attrs)
          attrs[:role_id].to_i
        end

        def plugin_key
          :lfg
        end
      end
    end
  end
end
