module Ops
  module Roles
    class SetSettings < ApplicationOperation
      # A channel is required only to ENABLE the plugin (TogglePlugin), not to save.
      def initialize(server_configuration:, channel_id:, notify_on_assign:, log_on_assign:)
        @server_configuration = server_configuration
        @channel_id = channel_id
        @notify_on_assign = notify_on_assign
        @log_on_assign = log_on_assign
      end

      def call
        setting = @server_configuration.role_setting || @server_configuration.build_role_setting
        transaction do
          setting.update!(channel_id: @channel_id, notify_on_assign: @notify_on_assign, log_on_assign: @log_on_assign)
        end
        ok(setting)
      end
    end
  end
end
