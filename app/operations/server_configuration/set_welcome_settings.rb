module Ops
  module ServerConfiguration
    class SetWelcomeSettings < ApplicationOperation
      # A channel is required only to ENABLE the plugin (TogglePlugin), not to save —
      # so admins can draft messages first. An empty message disables that announcement.
      def initialize(server_configuration:, channel_id:, join_message:, leave_message:)
        @server_configuration = server_configuration
        @channel_id = channel_id
        @join_message = join_message
        @leave_message = leave_message
      end

      def call
        setting = @server_configuration.welcome_settings || @server_configuration.build_welcome_settings
        transaction do
          setting.update!(channel_id: @channel_id, join_message: @join_message, leave_message: @leave_message)
        end
        ok(setting)
      end
    end
  end
end
