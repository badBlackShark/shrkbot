# Set the channel the logging sink posts to. A channel is required (logging
# can't run without one, #16); clearing isn't a feature yet.
# ponytail: the @everyone-visibility warning (#16) needs synced channel
# permission-overwrites — added in Phase 5.
class SetLoggingChannel < ApplicationOperation
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
