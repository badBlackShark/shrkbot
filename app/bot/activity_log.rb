# frozen_string_literal: true

module ActivityLog
  SUPPRESS_MENTIONS = {parse: []}.freeze

  module_function

  def post(server_configuration, bot:, title:, body:, meta:, image_url: nil, allowed_mentions: SUPPRESS_MENTIONS)
    channel_id = server_configuration.logging_setting.channel_id
    return unless channel_id

    deliver(bot, channel_id, entry(title, body, meta, image_url:), allowed_mentions:)
  end

  def enabled?(server_configuration, action)
    return false unless server_configuration.plugins.enabled.exists?(key: :logging)

    server_configuration.logging_setting.action_enabled?(action)
  end

  def entry(title, body, meta, image_url: nil)
    blocks = [Discord::Components.text("**#{title}**\n#{body}\n-# #{meta}")]
    blocks << Discord::Components.media_gallery([image_url]) if image_url
    Discord::Components.container(blocks)
  end

  def deliver(bot, channel_id, entry, allowed_mentions: SUPPRESS_MENTIONS)
    channel = bot.channel(channel_id)
    return unless channel

    Discord::Components.send_to(channel, entry, allowed_mentions:)
  rescue => e
    Rails.logger.warn("[ActivityLog] could not write to ##{channel_id}: #{e.class}: #{e.message}")
  end

  private_class_method :entry, :deliver
end
