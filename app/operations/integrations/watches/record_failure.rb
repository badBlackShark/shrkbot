# frozen_string_literal: true

module Ops
  module Integrations
    module Watches
      class RecordFailure < ApplicationOperation
        receives :watch, :error

        def call
          now = Time.current
          watch.update!(
            failing_since: continuing? ? watch.failing_since : now,
            last_error: "#{error.class}: #{error.message}",
            polled_at: now
          )
          ok
        end

        private

        def continuing?
          watch.failing_since.present? && watch.polled_at > ::Integrations::Watch::DORMANT_AFTER.ago
        end
      end
    end
  end
end
