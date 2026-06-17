module Ops
  module Roles
    class RemoveAssignableRole < ApplicationOperation
      def initialize(assignable_role:)
        @assignable_role = assignable_role
      end

      def call
        transaction { @assignable_role.destroy! }
        ok(@assignable_role)
      end
    end
  end
end
