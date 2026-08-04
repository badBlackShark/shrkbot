# frozen_string_literal: true

module Moderation
  class MemberBanLog < MemberActionLog
    on :audit_log_entry, action: :member_ban_add
    event_key :member_banned
  end
end
