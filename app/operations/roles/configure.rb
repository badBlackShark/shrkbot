# frozen_string_literal: true

module Ops
  module Roles
    class Configure < ApplicationOperation
      include Ops::PluginConfiguration

      receives :server_configuration, :channel_id, :enabled, :role_sets

      def call
        setting = server_configuration.role_setting
        @old_default_channel_id = setting.channel_id
        setting.channel_id = channel_id.presence
        activation = staged_activation

        return failure(messages(setting, activation), value: activation) unless setting.valid? && activation.valid?

        ActiveRecord::Base.transaction do
          setting.save!
          reconcile_sets(setting)
          activation.save!
        end
        plan.publish
        ok(activation)
      rescue ActiveRecord::RecordInvalid => error
        failure([error.record.errors.full_messages.to_sentence], value: activation)
      end

      private

      def reconcile_sets(setting)
        kept = role_sets.reject { |attrs| truthy?(attrs[:_destroy]) }.filter_map do |attrs|
          set = find_or_build_set(setting, attrs)
          next unless set

          old_channel = set.channel_override || @old_default_channel_id
          set.assign_attributes(
            name: attrs[:name],
            selection_mode: attrs[:selection_mode],
            channel_override: attrs[:channel_override].presence
          )
          reconcile_menu(set, old_channel)
          set.save!
          reconcile_roles(set, assignable_ids(attrs))
          plan.post(set) if menus_enabled?
          set.id
        end
        destroy_dropped_sets(setting, kept)
      end

      def destroy_dropped_sets(setting, kept)
        doomed = setting.role_sets.where.not(id: kept)
        doomed.each do |set|
          next if set.message_id.nil?

          plan.delete(
            channel_id: set.channel_override || @old_default_channel_id,
            message_id: set.message_id
          )
        end
        doomed.destroy_all
      end

      def find_or_build_set(setting, attrs)
        return setting.role_sets.find_by(id: attrs[:id]) if attrs[:id].present?

        setting.role_sets.new(position: next_position)
      end

      def reconcile_roles(set, role_ids)
        existing = set.assignable_roles.index_by { |role| role.role_id }
        role_ids.each_with_index do |role_id, index|
          role = existing[role_id] || set.assignable_roles.new(role_id:)
          role.update!(position: index)
        end
        set.assignable_roles.where.not(role_id: role_ids).destroy_all
      end

      def assignable_ids(attrs)
        Array(attrs[:role_ids]).map(&:to_i) & valid_role_ids
      end

      def valid_role_ids
        @valid_role_ids ||= ::Roles::AssignableServerRoles.new(server_configuration).assignable_ids
      end

      def next_position
        @next_position = existing_max_position if @next_position.nil?
        @next_position += 1
      end

      def existing_max_position
        server_configuration.role_setting.role_sets.maximum(:position) || -1
      end

      def plugin_key
        :roles
      end

      def reconcile_menu(set, old_channel)
        return if set.message_id.nil?

        if effective_channel(set) != old_channel
          plan.delete(channel_id: old_channel, message_id: set.message_id)
          set.message_id = nil
        elsif !menus_enabled?
          plan.remove(set)
        end
      end

      def effective_channel(set)
        set.channel_override || channel_id.to_i
      end

      def menus_enabled?
        truthy?(enabled)
      end

      def plan
        @plan ||= ::Roles::MenuSyncPlan.new
      end

      def truthy?(value)
        ActiveModel::Type::Boolean.new.cast(value)
      end
    end
  end
end
