# Fun, trolly stuff goes in here
module FunStuff
  extend Discordrb::EventContainer
  extend Discordrb::Commands::CommandContainer

  message(contains: /^lol$/i) do |event|
    event.respond '- Rondo' if (1..100).to_a.sample == 1
  end

  attrs = {
    usage: 'intensify <message>',
    description: 'Intensifies a message.'
  }
  command :intensify, attrs do |_event, *args|
    "*#{args.join(' ').split('').join(' ')}*"
  end

  message(with_text: 'ping') do |event|
    next unless SHRK.permission?(event.user, 2, event.server)
    message = event.respond 'fuck off'
    sleep 10
    message.edit "I mean, 'pong'"
    message.react(Emojis.name_to_unicode('heart'))
  end

  message(contains: /^ayy$/i) do |event|
    event.respond 'lmao' if (1..5).to_a.sample == 1
  end
end
