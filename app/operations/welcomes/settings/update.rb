module Ops
  module Welcomes
    module Settings
      class Update < ApplicationOperation
        receives :server_configuration, :channel_id, :join_message, :leave_message

        def call
          setting = server_configuration.welcome_settings || server_configuration.build_welcome_settings
          setting.update!(channel_id: channel_id, join_message: join_message, leave_message: leave_message)
          ok(setting)
        end
      end
    end
  end
end
