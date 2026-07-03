# frozen_string_literal: true

module Ops
  module Welcomes
    module Settings
      class Update < ApplicationOperation
        receives :server_configuration, :channel_id, :join_message, :leave_message

        def call
          setting = server_configuration.welcome_settings
          setting.update!(channel_id:, join_message:, leave_message:)
          ok(setting)
        end
      end
    end
  end
end
