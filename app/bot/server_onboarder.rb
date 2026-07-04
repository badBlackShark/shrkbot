# frozen_string_literal: true

module ServerOnboarder
  module_function

  def notify(bot, server, config)
    return if config.onboarded_at?

    bot.pm_channel(server.owner.id).send_message(message(server))
    config.update!(onboarded_at: Time.current)
  rescue => e
    Rails.logger.error("[ServerOnboarder] could not onboard server #{server.id}: #{e.class}: #{e.message}")
  end

  def message(server)
    url = dashboard_url(server)
    return message_without_link(server) if url.nil?

    <<~MSG.strip
      👋 Thanks for adding shrkbot!

      shrkbot is configured through the web dashboard. Set up #{server.name} here:
      #{url}

      Sign in with Discord to enable plugins and manage settings.
    MSG
  end

  def message_without_link(server)
    <<~MSG.strip
      👋 Thanks for adding shrkbot!

      shrkbot is configured through the web dashboard. Sign in with Discord there to set up #{server.name} — enable plugins and manage settings.
    MSG
  end

  def dashboard_url(server)
    base = BotConfig.web_base_url
    return if base.blank?

    "#{base.chomp("/")}/servers/#{server.id}"
  end
end
