# Fun, trolly stuff goes in here
module FunStuff
  extend Discordrb::EventContainer
  extend Discordrb::Commands::CommandContainer

  message(contains: /^lol$/i) do |event|
    event.respond '- Rondo' if (1..100).to_a.sample == 1
  end
end
