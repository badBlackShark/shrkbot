# frozen_string_literal: true

module Ops
  module Integrations
    module Twitch
      module Streams
        class TransitionAll < ApplicationOperation
          self.transactional = false

          receives :observations

          def call
            bugs = []
            observations.each do |watch, observation|
              Transition.call(watch:, observation:)
            rescue => error
              log_bug(watch, error)
              if ::NotifiesOwner.claim("twitch/streams/bug/#{watch.id}/#{error.class}")
                Rails.error.report(error, severity: :error)
                bugs << "#{watch.label}: #{error.class}: #{error.message}"
              end
            end
            ::Integrations::ReportPollBugsJob.perform_later(bugs) if bugs.any?
            ok
          end

          private

          def log_bug(watch, error)
            Rails.logger.error("Integrations: Twitch stream transition for #{watch.label} failed: #{error.full_message(highlight: false)}")
          end
        end
      end
    end
  end
end
