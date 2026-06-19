module Ops
  module Roles
    class RemoveAssignableRole < ApplicationOperation
      def initialize(assignable_role:)
        @assignable_role = assignable_role
      end

      def call
        transaction do
          @assignable_role.destroy!
        end
        ok(@assignable_role)
      end
    end
  end
end
