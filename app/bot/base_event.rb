class BaseEvent
  include WithConnection

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
