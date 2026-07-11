# frozen_string_literal: true

module Moderation
  class MemberKickLog < MemberActionLog
    on :member_leave
    event_key :member_kicked

    private

    def loggable?
      attribution.present?
    end

    def entry
      MemberLog::ActivityEntry.build(
        event_key: :member_kicked,
        target: event.user,
        moderator: attribution.moderator,
        reason: attribution.reason
      )
    end

    def attribution
      return @attribution if defined?(@attribution)

      @attribution = MemberLog::AuditLogLookup.attribution(event.server, action: :member_kick, target_id: event.user.id)
    end
  end
end
