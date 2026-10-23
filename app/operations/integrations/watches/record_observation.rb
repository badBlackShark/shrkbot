# frozen_string_literal: true

module Ops
  module Integrations
    module Watches
      class RecordObservation < ApplicationOperation
        FRESHNESS_WINDOW = 24.hours

        receives :watch, :events

        def call
          now = Time.current
          unseen = events.reject { |event| seen_ids.include?(event.subject_key) }
          remember(unseen)
          published = publish(unseen)
          watch.update!(
            primed_at: watch.primed_at || now,
            polled_at: now,
            failing_since: nil,
            last_error: nil,
            broken_reported_at: nil
          )
          ok(published)
        end

        private

        def primed?
          watch.primed_at.present?
        end

        def seen_ids
          @seen_ids ||= watch.seen_items.where(external_id: events.map(&:subject_key)).pluck(:external_id).to_set
        end

        def remember(unseen)
          rows = unseen.map { |event| {watch_id: watch.id, external_id: event.subject_key} }
          ::Integrations::SeenItem.insert_all(rows, unique_by: [:watch_id, :external_id])
        end

        def publish(unseen)
          return prime(unseen) unless primed?

          fresh = unseen.select { |event| event.occurred_at >= FRESHNESS_WINDOW.ago }
          log_skipped(unseen.size - fresh.size)
          fresh.select { |event| persist(event) }
        end

        def persist(event)
          return true if event.save

          Rails.logger.warn("Integrations: dropped invalid #{event.class} #{event.subject_key} for #{watch.watcher} #{watch.external_id}: #{event.errors.full_messages.to_sentence}")
          false
        end

        def prime(unseen)
          Rails.logger.info("Integrations: primed #{watch.watcher} #{watch.external_id} with #{unseen.size} items")
          []
        end

        def log_skipped(count)
          return if count.zero?

          Rails.logger.info("Integrations: skipped #{count} stale items for #{watch.watcher} #{watch.external_id}")
        end
      end
    end
  end
end
