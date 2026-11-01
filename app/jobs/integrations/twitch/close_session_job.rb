# frozen_string_literal: true

module Integrations
  module Twitch
    class CloseSessionJob < ApplicationJob
      queue_as :default
      discard_on ActiveJob::DeserializationError

      def perform(watch, offline_since)
        Ops::Integrations::Twitch::Streams::Transition.call(
          watch:,
          observation: Close.new(offline_since:)
        )
      end
    end
  end
end
