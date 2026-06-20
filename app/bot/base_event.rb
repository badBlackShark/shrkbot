class BaseEvent
  include WithConnection

  class << self
    def on(*values, **attributes)
      if values.any?
        @discord_events = values
        @event_attributes = attributes
      end
      @discord_events ||= []
    end

    def discord_events
      on
    end

    def event_attributes
      @event_attributes ||= {}
    end

    def dispatch(event)
      new(event).call
    end

    def registrable
      discord_events.any?
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
    nil
  end

  def handle
    raise AbstractMethodError, "#{self.class} must implement #handle"
  end
end
