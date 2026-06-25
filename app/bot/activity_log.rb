# frozen_string_literal: true

module ActivityLog
  module_function

  def record(server_configuration, plugin, event, bot:, **options)
    return unless enabled?(server_configuration, "#{plugin}.#{event}")

    channel_id = server_configuration.logging_setting.channel_id
    return unless channel_id

    deliver(bot, channel_id, render(plugin, event, options))
  end

  def enabled?(server_configuration, action)
    return false unless server_configuration.plugins.enabled.exists?(key: :logging)

    server_configuration.logging_setting.action_enabled?(action)
  end

  def render(plugin, event, options)
    I18n.t("activity_log.#{plugin}.#{event}", locale: :en, raise: true, **humanize(options))
  end

  def humanize(options)
    options.transform_values do |value|
      value.is_a?(Array) ? value.to_sentence : value
    end
  end

  def deliver(bot, channel_id, text)
    bot.channel(channel_id)&.send_message(text)
  rescue => e
    Rails.logger.warn("[ActivityLog] could not write to ##{channel_id}: #{e.class}: #{e.message}")
  end

  private_class_method :enabled?, :render, :humanize, :deliver
end
