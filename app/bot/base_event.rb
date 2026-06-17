class BaseEvent
  include WithConnection

  class << self
    def on(value = nil)
      @discord_event = value if value
      @discord_event
    end

    def discord_event
      on
    end

    def dispatch(event)
      new(event).call
    end

    def registrable
      discord_event.present?
    end
  end

  def initialize(event)
    @event = event
  end

  attr_reader :event

  def call
    with_connection { handle }
  rescue => e
    Rails.logger.error("[#{self.class.name}] #{e.class}: #{e.message}")
    OwnerNotifier.report(bot: event.bot, error: e, source: "event #{self.class.name}")
    nil # events have no interaction to reply to; swallow after logging
  end

  def handle
    raise AbstractMethodError, "#{self.class} must implement #handle"
  end
end
