module Ops
  module Logging
    class SetChannel < ApplicationOperation
      def initialize(server_configuration:, channel_id:)
        @server_configuration = server_configuration
        @channel_id = channel_id
      end

      def call
        return failure("A channel is required.") if @channel_id.blank?

        setting = @server_configuration.logging_setting || @server_configuration.build_logging_setting
        transaction { setting.update!(channel_id: @channel_id) }
        ok(setting, warnings: visibility_warnings)
      end

      private

      def visibility_warnings
        channel = @server_configuration.server_channels.find_by(discord_id: @channel_id)
        return [] unless channel&.everyone_visible?

        ["This channel is visible to @everyone; mod-action logs would be public."]
      end
    end
  end
end
