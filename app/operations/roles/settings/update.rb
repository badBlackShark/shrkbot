module Ops
  module Roles
    module Settings
      class Update < ApplicationOperation
        receives :server_configuration, :channel_id, :notify_on_assign, :log_on_assign

        def execute
          setting = server_configuration.role_setting || server_configuration.build_role_setting
          setting.update!(channel_id: channel_id, notify_on_assign: notify_on_assign, log_on_assign: log_on_assign)
          ok(setting)
        end
      end
    end
  end
end
