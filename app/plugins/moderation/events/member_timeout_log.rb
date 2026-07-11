# frozen_string_literal: true

module Moderation
  class MemberTimeoutLog < MemberActionLog
    on :member_update
    event_key :member_timed_out

    private

    def loggable?
      member&.communication_disabled? && attribution.present? && first_sighting?
    end

    def entry
      MemberLog::ActivityEntry.build(
        :member_timed_out,
        target: member,
        moderator: attribution.moderator,
        reason: attribution.reason,
        timeout_until: member.communication_disabled_until
      )
    end

    def first_sighting?
      MemberLog::TimeoutLogLedger.instance.first_sighting?(
        guild_id: event.server.id,
        user_id: member.id,
        expires_at: member.communication_disabled_until
      )
    end

    def member
      return @member if defined?(@member)

      @member = event.user
    end

    def attribution
      return @attribution if defined?(@attribution)

      @attribution = MemberLog::AuditLogLookup.attribution(event.server, action: :member_update, target_id: member.id) do |candidate|
        candidate.changes.is_a?(Hash) && candidate.changes["communication_disabled_until"]&.new.present?
      end
    end
  end
end
