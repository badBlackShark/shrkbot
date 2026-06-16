module Ops
  class SetLoggingChannel < ApplicationOperation
    # Phase 5: warn when the channel is @everyone-visible (#16) — needs synced overwrites.
    def initialize(server_configuration:, channel_id:)
      @server_configuration = server_configuration
      @channel_id = channel_id
    end

    def call
      return failure("A channel is required.") if @channel_id.blank?

      setting = @server_configuration.logging_setting || @server_configuration.build_logging_setting
      transaction { setting.update!(channel_id: @channel_id) }
      ok(setting)
    end
  end
end
