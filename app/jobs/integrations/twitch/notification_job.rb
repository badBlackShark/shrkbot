# frozen_string_literal: true

module Integrations
  module Twitch
    class NotificationJob < ApplicationJob
      queue_as :default

      rescue_from Error, with: :warn_failure
      retry_on Unavailable, wait: 5.seconds, attempts: 3 do |job, error|
        job.send(:warn_failure, error)
      end

      def perform(type, event)
        watch = ChannelWatcher.followed_for_live.find_by(external_id: event.fetch("broadcaster_user_id"))
        return unless watch

        observation = observation(type, event)
        return unless observation

        Ops::Integrations::Twitch::Streams::Transition.call(watch:, observation:)
      end

      private

      def warn_failure(error)
        type, event = arguments
        Rails.logger.warn("Integrations: Twitch #{type} for channel #{event["broadcaster_user_id"]} failed, the stream reconcile catches up: #{error.class}: #{error.message}")
      end

      def observation(type, event)
        case type
        when "stream.online" then online(event)
        when "stream.offline" then Offline.new
        when "channel.update" then ChannelUpdate.from_event(event)
        end
      end

      def online(event)
        return live_now(event) if executions > 1

        channel = Channels.new.for([event.fetch("broadcaster_user_id")]).first
        Live.from_online(event, channel) if channel
      end

      def live_now(event)
        stream = Streams.new.live([event.fetch("broadcaster_user_id")]).first
        Live.from_stream(stream) if stream
      end
    end
  end
end
