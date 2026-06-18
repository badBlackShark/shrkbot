module Ops
  module Roles
    class DeleteSet < ApplicationOperation
      def initialize(role_set:)
        @role_set = role_set
      end

      def call
        transaction { @role_set.destroy! }
        ok(@role_set)
      end
    end
  end
end
