# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module ServerRole
      module Attributes
        module_function

        def call(role)
          {
            name: role[:name],
            position: role[:position],
            managed: role[:managed],
            color: role[:color] || 0,
            permissions: role[:permissions] || 0
          }
        end
      end
    end
  end
end
