# frozen_string_literal: true

module Ops
  module Integrations
    module Watches
      class MarkBrokenReported < ApplicationOperation
        receives :watches

        def call
          ::Integrations::Watch.where(id: watches.map(&:id)).update_all(broken_reported_at: Time.current)
          ok
        end
      end
    end
  end
end
