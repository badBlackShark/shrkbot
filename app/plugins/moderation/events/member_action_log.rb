# frozen_string_literal: true

module Moderation
  class MemberActionLog < Bot::BaseEvent
    def handle
      return unless server_configuration
      return unless Bot::ActivityLog.enabled?(server_configuration, "moderation.#{self.class.event_key}")
      return if performed_by_shrkbot?
      return unless target
      return unless loggable?

      Bot::ActivityLog.post(
        server_configuration,
        bot: event.bot,
        allowed_mentions: {parse: [], users: [target.id]},
        **activity_entry
      )
    end

    class << self
      def event_key(value = nil)
        @event_key = value if value
        @event_key
      end
    end

    private

    def activity_entry
      MemberLog::ActivityEntry.build(
        event_key: self.class.event_key,
        target:,
        moderator: audit_entry.user,
        reason: audit_entry.reason,
        **entry_options
      )
    end

    def entry_options
      {}
    end

    def loggable?
      true
    end

    def target
      return @target if defined?(@target)

      @target = audit_entry.target
    end

    def audit_entry
      event.entry
    end

    def performed_by_shrkbot?
      event.user_id == event.bot.profile.id
    end

    def server_configuration
      @server_configuration ||= ServerConfiguration.find_by(discord_id: event.server&.id)
    end
  end
end
