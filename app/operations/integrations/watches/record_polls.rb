# frozen_string_literal: true

module Ops
  module Integrations
    module Watches
      class RecordPolls < ApplicationOperation
        receives :watches

        def call
          ::Integrations::Watch.where(id: watches.map(&:id)).update_all(polled_at: Time.current, failing_since: nil, last_error: nil)
          ok
        end
      end
    end
  end
end
