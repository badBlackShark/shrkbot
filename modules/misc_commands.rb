# All the hardcoded BS goes in here :)
module MiscCommands
  extend Discordrb::EventContainer
  extend Discordrb::Commands::CommandContainer

  message(with_text: 'ping') do |event|
    next unless event.user.id == 94558130305765376
    message = event.respond 'fuck off'
    sleep 10
    message.edit "I mean, 'pong'"
    message.react(Emojis.name_to_unicode('heart'))
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'setGame <game>',
    description: 'Sets what the bots is playing.'
  }
  command :setgame, attrs do |event, *args|
    game = args.join(' ')
    SHRK.game = game
    event.message.delete
  end

  attrs = {
    permission_level: 1,
    permission_message: false,
    usage: 'REEEEE',
    description: 'REEEEE!'
  }
  command :reeeee, attrs do |event|
    event.channel.send_embed('') do |embed|
      embed.image = Discordrb::Webhooks::EmbedImage.new(url: 'https://cdn.discordapp.com/attachments/345748230816006156/347070498078851103/Eternally_screaming.gif')
    end
    event.message.delete
  end
end
