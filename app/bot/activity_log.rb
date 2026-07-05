# frozen_string_literal: true

module ActivityLog
  SUPPRESS_MENTIONS = {parse: []}.freeze

  module_function

  def post(server_configuration, bot:, title:, body:, meta:)
    channel_id = server_configuration.logging_setting.channel_id
    return unless channel_id

    deliver(bot, channel_id, entry(title, body, meta))
  end

  def enabled?(server_configuration, action)
    return false unless server_configuration.plugins.enabled.exists?(key: :logging)

    server_configuration.logging_setting.action_enabled?(action)
  end

  def entry(title, body, meta)
    Discord::Components.container(
      [Discord::Components.text("**#{title}**\n#{body}\n-# #{meta}")]
    )
  end

  def deliver(bot, channel_id, entry)
    bot.channel(channel_id)&.send_message(nil, false, nil, nil, SUPPRESS_MENTIONS, nil, entry[:components], entry[:flags])
  rescue => e
    Rails.logger.warn("[ActivityLog] could not write to ##{channel_id}: #{e.class}: #{e.message}")
  end

  private_class_method :entry, :deliver
end
