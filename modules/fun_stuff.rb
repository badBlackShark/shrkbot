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
end
