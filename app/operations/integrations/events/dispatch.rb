# frozen_string_literal: true

module Ops
  module Integrations
    module Events
      class Dispatch < ApplicationOperation
        self.transactional = false

        receives :events

        def call
          handled = events.select { |event| enqueue(event) }
          ::Integrations::Event.where(id: handled.map(&:id)).update_all(dispatched_at: Time.current) if handled.any?
          ok(handled)
        end

        private

        def enqueue(event)
          handlers = ::Integrations::Bus.handlers_for(event)
          handlers.each { |handler| handler.perform_later(event) }
          handlers.any?
        end
      end
    end
  end
end
