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
    <<~MSG.strip
      👋 Thanks for adding shrkbot!

      shrkbot is configured through the web dashboard. Set up #{server.name} here:
      #{dashboard_url(server)}

      Sign in with Discord to enable plugins and manage settings.
    MSG
  end

  def dashboard_url(server)
    BotConfig.server_config_url(server.id)
  end
end
