# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module BotRolePosition
      class Sync < ApplicationOperation
        receives :server_configuration, :position

        def call
          server_configuration.update!(bot_role_position: position)
          ok(server_configuration)
        end
      end
    end
  end
end
