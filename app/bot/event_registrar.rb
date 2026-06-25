# frozen_string_literal: true

class EventRegistrar
  def initialize(bot, events:)
    @bot = bot
    @events = events.select(&:registrable)
  end

  attr_reader :bot, :events

  def register_all
    events.each do |klass|
      klass.discord_events.each do |discord_event|
        if klass.event_attributes.empty?
          bot.public_send(discord_event) { |event| klass.dispatch(event) }
        else
          bot.public_send(discord_event, klass.event_attributes) { |event| klass.dispatch(event) }
        end
      end
    end
  end
end
