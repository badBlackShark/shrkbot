# frozen_string_literal: true

module Moderation
  class MemberBanLog < MemberActionLog
    on :user_ban
    event_key :member_banned

    private

    def loggable?
      true
    end

    def entry
      attribution = AuditLogLookup.attribution(event.server, action: :member_ban_add, target_id: event.user.id)
      ActivityEntry.build(
        :member_banned,
        target: event.user,
        moderator: attribution&.moderator,
        reason: attribution&.reason
      )
    end
  end
end
