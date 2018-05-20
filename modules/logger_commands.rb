# Some commands to go with SHRKLogger
module LoggerCommands
  extend Discordrb::Commands::CommandContainer

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'setLogChannel <channelName>',
    description: 'Sets the channel where the bot logs role assigns.',
    min_args: 1
  }
  # This is the manual setter, the database attempts to assign a default value when initializing.
  command :setlogchannel, attrs do |event, *args|
    channel = event.server.channels.find { |s_channel| s_channel.name.casecmp?(args.join(' ')) }
    next "That channel doesn't exist." unless channel

    DB.update_value("shrk_server_#{event.server.id}".to_sym, :log_channel, channel.id)
    Reactions.confirm(event.message)
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'logChannel?',
    description: 'Sends a message in the log channel, in case you forgot which one it is.'
  }
  command :logchannel?, attrs do |event|
    log_channel = DB.read_value("shrk_server_#{event.server.id}".to_sym, :log_channel)

    next "The log channel is <##{log_channel}>." if log_channel

    'There is no log channel. Please set one using `.setLogChannel <channelName>`.'
  end
end
