module Ops
  module Welcomes
    class SetSettings < ApplicationOperation
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
