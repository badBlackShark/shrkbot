# Fun, trolly stuff goes in here
module FunStuff
  extend Discordrb::EventContainer
  extend Discordrb::Commands::CommandContainer
  @ping_whitelist = [94558130305765376,377840962128445441,98499497348321280,155963500265603072,305860996029874178]

  message(contains: /^lol$/i) do |event|
    event.respond '- Rondo' if (1..100).to_a.sample == 1
  end

  attrs = {
    usage: 'intensify <message>',
    description: 'Intensifies a message.'
  }
  command :intensify, attrs do |event, *args|
    event.message.delete
    "*#{args.join(' ').split('').join(' ')}*"
  end

  message(with_text: 'ping') do |event|
    next unless @ping_whitelist.include?(event.user.id)
    message = event.respond 'fuck off'
    sleep 10
    message.edit "I mean, 'pong'"
    message.react(Emojis.name_to_unicode('heart'))
  end

  message(contains: /^a[y]{2,5}$/i) do |event|
    event.respond 'lmao' if (1..5).to_a.sample == 1
  end
end
