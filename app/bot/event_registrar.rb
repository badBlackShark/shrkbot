class EventRegistrar
  def initialize(bot, events:)
    @bot = bot
    @events = events.select(&:registrable)
  end

  attr_reader :bot, :events

  def register_all
    events.each do |klass|
      bot.public_send(klass.discord_event) { |event| klass.dispatch(event) }
    end
  end
end
