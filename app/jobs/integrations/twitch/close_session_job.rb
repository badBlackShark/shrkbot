# frozen_string_literal: true

module Integrations
  module Twitch
    class CloseSessionJob < ApplicationJob
      queue_as :default
      discard_on ActiveJob::DeserializationError

      def perform(watch, offline_since)
        stream = Streams.new.live([watch.external_id]).first
        Ops::Integrations::Twitch::Streams::Transition.call(
          watch:,
          observation: stream ? Live.from_stream(stream) : Close.new(offline_since:)
        )
      rescue Error => error
        Rails.logger.warn("Integrations: Twitch close check for #{watch.label} failed, a stale session ends on a later reconcile: #{error.class}: #{error.message}")
      end
    end
  end
end
