module WebhookCommands
  extend Discordrb::EventContainer
  extend Discordrb::Commands::CommandContainer

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'clearWebhooks',
    description: 'Clears all shrkbot webhooks in this channel.'
  }
  command :clearwebhooks, attrs do |event|
    WH.delete_webhooks(event.channel)
    Reactions.confirm(event.message)
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'refreshWebhooks',
    description: 'Clears all shrkbot webhooks in this channel, and creates a new one.'
  }
  command :refreshwebhooks, attrs do |event|
    WH.delete_webhooks(event.channel)
    WH.create_webhook(event.channel.id)
    Reactions.confirm(event.message)
  end

  channel_create do |event|
    WH.create_webhook(event.channel.id) unless event.channel.private?
  end
end
