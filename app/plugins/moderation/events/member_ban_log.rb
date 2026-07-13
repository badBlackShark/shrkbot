# frozen_string_literal: true

module Moderation
  class MemberBanLog < MemberActionLog
    on :user_ban
    event_key :member_banned

    private

    def loggable?
      !performed_by_shrkbot?(attribution&.moderator)
    end

    def entry
      MemberLog::ActivityEntry.build(
        event_key: :member_banned,
        target: event.user,
        moderator: attribution&.moderator,
        reason: attribution&.reason
      )
    end

    def attribution
      return @attribution if defined?(@attribution)

      @attribution = MemberLog::AuditLogLookup.attribution(event.server, action: :member_ban_add, target_id: event.user.id)
    end
  end
end
