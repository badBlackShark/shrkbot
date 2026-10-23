# frozen_string_literal: true

module Ops
  module Integrations
    module Watches
      class RecordObservation < ApplicationOperation
        FRESHNESS_WINDOW = 48.hours

        receives :watch, :events

        def call
          now = Time.current
          unseen = fresh_events.reject { |event| seen_ids.include?(event.subject_key) }
          remember(unseen)
          published = publish(unseen)
          dispatch_after_commit(published)
          watch.update!(
            primed_at: watch.primed_at || now,
            polled_at: now,
            failing_since: nil,
            last_error: nil
          )
          ok(published)
        end

        private

        def primed?
          watch.primed_at.present?
        end

        def fresh_events
          @fresh_events ||= events.select { |event| event.occurred_at >= FRESHNESS_WINDOW.ago }
        end

        def seen_ids
          @seen_ids ||= watch.seen_items.where(external_id: fresh_events.map(&:subject_key)).pluck(:external_id).to_set
        end

        def remember(unseen)
          rows = unseen.map { |event| {watch_id: watch.id, external_id: event.subject_key} }
          ::Integrations::SeenItem.insert_all(rows, unique_by: [:watch_id, :external_id])
        end

        def publish(unseen)
          return prime(unseen) unless primed?

          unseen.select { |event| persist(event) }
        end

        def persist(event)
          return true if event.save

          Rails.logger.warn("Integrations: dropped invalid #{event.class} #{event.subject_key} for #{watch.watcher} #{watch.external_id}: #{event.errors.full_messages.to_sentence}")
          false
        end

        def dispatch_after_commit(published)
          return if published.empty?

          ActiveRecord.after_all_transactions_commit do
            Ops::Integrations::Events::Dispatch.call(events: published)
          end
        end

        def prime(unseen)
          Rails.logger.info("Integrations: primed #{watch.watcher} #{watch.external_id} with #{unseen.size} items")
          []
        end
      end
    end
  end
end
