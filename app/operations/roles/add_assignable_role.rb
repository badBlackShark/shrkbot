module Ops
  module Roles
    class AddAssignableRole < ApplicationOperation
      def initialize(role_set:, role_id:, label:, description: nil, emoji: nil)
        @role_set = role_set
        @role_id = role_id
        @label = label
        @description = description
        @emoji = emoji
      end

      def call
        role = transaction do
          @role_set.assignable_roles.create!(
            role_id: @role_id,
            label: @label,
            description: @description,
            emoji: @emoji,
            position: next_position
          )
        end
        ok(role)
      end

      private

      def next_position
        (@role_set.assignable_roles.maximum(:position) || -1) + 1
      end
    end
  end
end
