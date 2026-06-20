module ActivityLog
  EVENTS = {
    role_gained: "roles.assignment",
    role_lost: "roles.assignment",
    roles_changed: "roles.assignment"
  }.freeze

  module_function

  def record(server_configuration, event, bot:, **options)
    action = EVENTS.fetch(event)
    return unless enabled?(server_configuration, action)

    channel_id = server_configuration.logging_setting.channel_id
    return unless channel_id

    deliver(bot, channel_id, render(event, options))
  end

  def enabled?(server_configuration, action)
    return false unless server_configuration.plugins.enabled.exists?(key: :logging)

    server_configuration.logging_setting&.action_enabled?(action) || false
  end

  def render(event, options)
    I18n.t("activity_log.#{event}", locale: :en, raise: true, **humanize(options))
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
