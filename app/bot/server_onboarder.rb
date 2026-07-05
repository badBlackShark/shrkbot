# frozen_string_literal: true

module ServerOnboarder
  module_function

  def notify(bot, server, config)
    return if config.onboarded_at?

    rendered = message(server)
    bot.pm_channel(server.owner.id).send_message(nil, false, nil, nil, nil, nil, rendered[:components], rendered[:flags])
    config.update!(onboarded_at: Time.current)
  rescue => e
    Rails.logger.error("[ServerOnboarder] could not onboard server #{server.id}: #{e.class}: #{e.message}")
  end

  def message(server)
    Discord::Components.container(
      [
        Discord::Components.text(body(server)),
        Discord::Components.separator,
        Discord::Components.text("-# Sign in with Discord to enable plugins and manage settings.")
      ]
    )
  end

  def body(server)
    "### Thanks for adding shrkbot!\n" \
      "shrkbot is set up entirely through the web dashboard. Configure **#{server.name}** here:\n" \
      "#{dashboard_url(server)}"
  end

  def dashboard_url(server)
    BotConfig.server_config_url(server.id)
  end
end
