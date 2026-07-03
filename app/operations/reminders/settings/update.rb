# frozen_string_literal: true

module Ops
  module Reminders
    module Settings
      class Update < ApplicationOperation
        receives :server_configuration, :force_dm_reminders

        def call
          server_configuration.update!(force_dm_reminders:)
          ok(server_configuration)
        end
      end
    end
  end
end
