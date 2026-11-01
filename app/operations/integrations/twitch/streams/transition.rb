# frozen_string_literal: true

module Ops
  module Integrations
    module Twitch
      module Streams
        class Transition < ApplicationOperation
          DroppedEvent = Class.new(StandardError)

          receives :watch, :observation

          def call
            watch.with_lock do
              outcome = ::Integrations::Twitch::Session.new(watch.state, now: Time.current).apply(observation)
              outcome.events.each { |event| event.watch = watch }
              watch.update!(state: outcome.state)
              recorded = Ops::Integrations::Events::Record.call(watch:, events: outcome.events).value
              raise DroppedEvent, "#{watch.label}: #{outcome.events.size - recorded.size} stream events were invalid" if recorded.size < outcome.events.size
              schedule_close(outcome.state.fetch("offline_at")) if outcome.went_offline
            end
            ok
          end

          private

          def schedule_close(offline_at)
            ActiveRecord.after_all_transactions_commit do
              ::Integrations::Twitch::CloseSessionJob.set(wait: ::Integrations::Twitch::Session::GRACE).perform_later(watch, offline_at)
            end
          end
        end
      end
    end
  end
end
