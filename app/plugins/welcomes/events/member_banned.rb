# frozen_string_literal: true

module Welcomes
  class MemberBanned < RemovalRecord
    on :audit_log_entry, action: :member_ban_add
  end
end
