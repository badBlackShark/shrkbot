# frozen_string_literal: true

module Ops
  module Roles
    module Settings
      class Update < ApplicationOperation
        receives :server_configuration, :channel_id

        def call
          setting = server_configuration.role_setting
          setting.update!(channel_id: channel_id)
          ok(setting)
        end
      end
    end
  end
end
