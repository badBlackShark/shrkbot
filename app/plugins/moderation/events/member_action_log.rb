# frozen_string_literal: true

module Moderation
  class MemberActionLog < Bot::BaseEvent
    def handle
      return unless server_configuration
      return unless Bot::ActivityLog.enabled?(server_configuration, "moderation.#{self.class.event_key}")
      return unless loggable?

      Bot::ActivityLog.post(
        server_configuration,
        bot: event.bot,
        **entry
      )
    end

    class << self
      def event_key(value = nil)
        @event_key = value if value
        @event_key
      end
    end

    private

    def performed_by_shrkbot?(moderator)
      moderator&.id == event.bot.profile.id
    end

    def loggable?
      raise AbstractMethodError, "#{self.class} must implement #loggable?"
    end

    def entry
      raise AbstractMethodError, "#{self.class} must implement #entry"
    end

    def server_configuration
      @server_configuration ||= ServerConfiguration.find_by(discord_id: event.server&.id)
    end
  end
end
