# Base for gateway event handlers (member_join, member_leave, button clicks…).
# Like BaseCommand it runs on a discordrb worker thread, so it shares the
# connection-checkout concern. Fleshed out per-event in Phase 4.
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
    nil # events have no interaction to reply to; swallow after logging
  end

  def handle = raise(NotImplementedError, "#{self.class} must implement #handle")
end
