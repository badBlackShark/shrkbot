# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module ServerRoles
      class Destroy < ApplicationOperation
        receives :server_role

        def call
          ok(server_role.destroy!)
        end
      end
    end
  end
end
