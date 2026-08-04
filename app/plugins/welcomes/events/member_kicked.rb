# frozen_string_literal: true

module Welcomes
  class MemberKicked < RemovalRecord
    on :audit_log_entry, action: :member_kick
  end
end
