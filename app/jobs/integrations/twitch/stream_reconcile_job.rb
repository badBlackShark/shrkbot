# frozen_string_literal: true

module Integrations
  module Twitch
    class StreamReconcileJob < ApplicationJob
      include TracksCheckFailures

      queue_as :default
      limits_concurrency(
        to: 1,
        key: ->(*) { "twitch-stream-reconcile" },
        duration: 10.minutes,
        on_conflict: :discard
      )

      def perform
        return unless Client.configured?

        watches = ChannelWatcher.live_checked.to_a
        return if watches.empty?

        live = fetch_live(watches)
        return if live.nil?

        transition_all(watches, live)
      end

      private

      def fetch_live(watches)
        live = Streams.new.live(watches.map(&:external_id)).index_by(&:user_id)
        clear_failing
        live
      rescue Error => error
        report(error)
        nil
      end

      def transition_all(watches, live)
        observations = watches.map do |watch|
          stream = live[watch.external_id]
          [watch, stream ? Live.from_stream(stream) : Offline.new]
        end
        Ops::Integrations::Twitch::Streams::TransitionAll.call(observations:)
      end

      def failure_key
        "twitch/streams"
      end

      def failure_label
        "Twitch streams"
      end

      def report_broken(message)
        ReportLiveCheckBrokenJob.perform_later(message)
      end
    end
  end
end
