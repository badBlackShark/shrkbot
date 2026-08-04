# frozen_string_literal: true

module Welcomes
  class PendingRemovals < ExpiringMemberSet
    retention 30.seconds
  end
end
