# frozen_string_literal: true

module Ops
  module Integrations
    module Events
      class Record < ApplicationOperation
        receives :watch, :events

        def call
          published = events.reject { |event| recorded?(event) }.select { |event| persist(event) }
          dispatch_after_commit(published)
          ok(published)
        end

        private

        def recorded?(event)
          already_recorded.include?([event.type, event.subject_key])
        end

        def already_recorded
          @already_recorded ||= ::Integrations::Event
            .where(watch:, subject_key: events.map(&:subject_key))
            .pluck(:type, :subject_key)
            .to_set
        end

        def persist(event)
          event.enrich
          return true if event.save

          Rails.logger.warn("Integrations: dropped invalid #{event.class} #{event.subject_key} for #{watch.watcher} #{watch.external_id}: #{event.errors.full_messages.to_sentence}")
          false
        end

        def dispatch_after_commit(published)
          return if published.empty?

          ActiveRecord.after_all_transactions_commit do
            Ops::Integrations::Events::Dispatch.call(events: published)
          rescue => error
            Rails.logger.warn("Integrations: dispatch failed for #{published.size} events of #{watch.watcher} #{watch.external_id}, the sweeper will retry: #{error.class}: #{error.message}")
          end
        end
      end
    end
  end
end
