# frozen_string_literal: true

module Moderation
  class MemberKickLog < MemberActionLog
    on :audit_log_entry, action: :member_kick
    event_key :member_kicked
  end
end
