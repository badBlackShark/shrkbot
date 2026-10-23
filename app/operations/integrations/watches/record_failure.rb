# frozen_string_literal: true

module Ops
  module Integrations
    module Watches
      class RecordFailure < ApplicationOperation
        receives :watch, :error

        def call
          now = Time.current
          watch.update!(failing_since: watch.failing_since || now, last_error: error.message, polled_at: now)
          ok
        end
      end
    end
  end
end
