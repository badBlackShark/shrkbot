# frozen_string_literal: true

module Moderation
  class MemberTimeoutLog < MemberActionLog
    on :audit_log_entry, action: :member_update
    event_key :member_timed_out

    private

    def loggable?
      timeout_until.present?
    end

    def entry_options
      {timeout_until:}
    end

    def timeout_until
      return @timeout_until if defined?(@timeout_until)

      expiry = audit_entry.changes["communication_disabled_until"]&.new
      @timeout_until = expiry && Time.zone.parse(expiry)
    end
  end
end
