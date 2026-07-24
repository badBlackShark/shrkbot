# frozen_string_literal: true

module Ops
  module Lfg
    class Configure < ApplicationOperation
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
        settings = server_configuration.lfg_settings
        settings.assign_attributes(
          cooldown_seconds:,
          post_lifetime_minutes:,
          default_min_membership_days: default_min_membership_days.presence,
          default_required_role_ids:,
          default_excluded_role_ids:,
          allowed_channel_ids:
        )
        activation = staged_activation

        return failure(messages(settings, activation), value: activation) unless settings.valid? && activation.valid?

        transaction do
          settings.save!
          reconcile_pingable_roles(settings)
          save_activation!(activation)
        end
        ok(activation)
      rescue ActiveRecord::RecordInvalid => error
        failure([error.record.errors.full_messages.to_sentence], value: activation)
      end

      private

      def reconcile_pingable_roles(settings)
        kept = pingable_roles.reject { |attrs| truthy?(attrs[:_destroy]) }.filter_map do |attrs|
          role_id = attrs[:role_id].to_i
          next if role_id.zero?

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

      def plugin_key
        :lfg
      end

      def truthy?(value)
        ActiveModel::Type::Boolean.new.cast(value)
      end
    end
  end
end
