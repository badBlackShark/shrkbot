# frozen_string_literal: true

module Ops
  module Integrations
    module Watches
      class RecordObservation < ApplicationOperation
        receives :watch, :events

        def call
          now = Time.current
          unseen = fresh_events.reject { |event| seen_ids.include?(event.subject_key) }
          remember(unseen)
          published = Ops::Integrations::Events::Record.call(watch:, events: unseen).value
          watch.update!(
            polled_at: now,
            failing_since: nil,
            last_error: nil
          )
          ok(published)
        end

        private

        def fresh_events
          @fresh_events ||= events.select { |event| event.occurred_at >= ::Integrations::Event::FRESHNESS_WINDOW.ago }
        end

        def seen_ids
          @seen_ids ||= watch.seen_items.where(external_id: fresh_events.map(&:subject_key)).pluck(:external_id).to_set
        end

        def remember(unseen)
          rows = unseen.map { |event| {watch_id: watch.id, external_id: event.subject_key} }
          ::Integrations::SeenItem.insert_all(rows, unique_by: [:watch_id, :external_id])
        end
      end
    end
  end
end
