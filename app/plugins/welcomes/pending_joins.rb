# frozen_string_literal: true

module Welcomes
  class PendingJoins < ExpiringMemberSet
    retention 24.hours
  end
end
