module ServerOnboarder
  WELCOME_MESSAGE = <<~MSG.strip
    👋 Thanks for adding shrkbot!

    shrkbot is configured through a web dashboard — setup details are on the way.
  MSG

  module_function

  def notify(bot, server, config)
    return if config.onboarded_at?

    bot.pm_channel(server.owner.id).send_message(WELCOME_MESSAGE)
    config.update!(onboarded_at: Time.current)
  rescue => e
    Rails.logger.error("[ServerOnboarder] could not onboard server #{server.id}: #{e.class}: #{e.message}")
  end
end
