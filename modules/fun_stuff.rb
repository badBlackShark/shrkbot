# Fun, trolly stuff goes in here
module FunStuff
  extend Discordrb::EventContainer
  extend Discordrb::Commands::CommandContainer

  message(contains: /^lol$/i) do |event|
    event.respond "- Rondo" if (1..100).to_a.sample == 1
  end

  command :roulette do |event|
    outcome = (1..6).to_a.sample == 1
    if event.user.id == 94558130305765376
      "I couldn't ever let you shoot yourself. #{Emojis.name_to_emoji('heart')}"
    elsif outcome
      event.respond "Unlucky. #{event.user.mention} shoots themself in the head, and dies."
      sleep 3
      Moderation.mute(event, event.user, "1m", "Died while playing roulette.")
      nil
    else
      "The revolver clicks, and #{event.user.mention} survives. Congratulations."
    end
  end
end
