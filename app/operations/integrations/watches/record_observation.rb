# frozen_string_literal: true

module Ops
  module Integrations
    module Watches
      class RecordObservation < ApplicationOperation
        receives :watch, :events

        def call
          now = Time.current
          published = Ops::Integrations::Events::Record.call(watch:, events: fresh_events).value
          watch.update!(
            polled_at: now,
            failing_since: nil,
            last_error: nil
          )
          ok(published)
        end

        private

        def fresh_events
          events.select { |event| event.occurred_at >= ::Integrations::Event::FRESHNESS_WINDOW.ago }
        end
      end
    end
  end
end
