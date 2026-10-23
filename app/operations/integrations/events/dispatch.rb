# frozen_string_literal: true

module Ops
  module Integrations
    module Events
      class Dispatch < ApplicationOperation
        self.transactional = false

        receives :events

        def call
          jobs_by_event = events.sort_by { |event| [event.occurred_at, event.id] }
            .to_h { |event| [event, jobs_for(event)] }
            .reject { |_event, jobs| jobs.empty? }
          ActiveJob.perform_all_later(jobs_by_event.values.flatten)
          stamp(jobs_by_event.keys)
          ok(jobs_by_event.keys)
        end

        private

        def jobs_for(event)
          ::Integrations::Bus.handlers_for(event).map { |handler| handler.new(event) }
        end

        def stamp(handled)
          ::Integrations::Event.where(id: handled.map(&:id)).update_all(dispatched_at: Time.current) if handled.any?
        end
      end
    end
  end
end
