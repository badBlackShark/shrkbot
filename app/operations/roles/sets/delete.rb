module Ops
  module Roles
    module Sets
      class Delete < ApplicationOperation
        receives :role_set

        def call
          role_set.destroy!
          ok(role_set)
        end
      end
    end
  end
end
