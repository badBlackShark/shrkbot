# frozen_string_literal: true

module Ops
  module Roles
    class Configure < ApplicationOperation
      receives :server_configuration, :channel_id, :enabled, :role_sets

      def call
        setting = server_configuration.role_setting
        setting.channel_id = channel_id.presence
        activation = staged_activation

        return failure(messages(setting, activation), value: activation) unless setting.valid? && activation.valid?

        ActiveRecord::Base.transaction do
          setting.save!
          reconcile_sets(setting)
          activation.save!
        end
        ok(activation)
      rescue ActiveRecord::RecordInvalid => error
        failure([error.record.errors.full_messages.to_sentence], value: activation)
      end

      private

      def reconcile_sets(setting)
        kept = role_sets.reject { |attrs| truthy?(attrs[:_destroy]) }.map do |attrs|
          set = find_or_build_set(setting, attrs)
          set.update!(name: attrs[:name], selection_mode: attrs[:selection_mode], channel_override: attrs[:channel_override].presence)
          reconcile_roles(set, assignable_ids(attrs))
          set.id
        end
        setting.role_sets.where.not(id: kept).destroy_all
      end

      def find_or_build_set(setting, attrs)
        return setting.role_sets.find(attrs[:id]) if attrs[:id].present?

        setting.role_sets.new(position: next_position(setting))
      end

      def reconcile_roles(set, role_ids)
        existing = set.assignable_roles.index_by { |role| role.role_id }
        role_ids.each_with_index do |role_id, index|
          role = existing[role_id] || set.assignable_roles.new(role_id: role_id)
          role.update!(position: index)
        end
        set.assignable_roles.where.not(role_id: role_ids).destroy_all
      end

      def assignable_ids(attrs)
        submitted = Array(attrs[:role_ids]).map(&:to_i)
        submitted & server_configuration.server_roles.pluck(:discord_id)
      end

      def next_position(setting)
        (setting.role_sets.maximum(:position) || -1) + 1
      end

      def staged_activation
        activation = server_configuration.plugin_activations.find_or_initialize_by(plugin: Plugin.find_by!(key: :roles))
        activation.enabled = enabled
        activation
      end

      def truthy?(value)
        ActiveModel::Type::Boolean.new.cast(value)
      end

      def messages(*records)
        records.flat_map { |record| record.errors.full_messages }
      end
    end
  end
end
