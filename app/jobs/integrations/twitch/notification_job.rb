# frozen_string_literal: true

module Integrations
  module Twitch
    class NotificationJob < ApplicationJob
      queue_as :default

      def perform(type, event)
        watch = Watch.demanded.find_by(watcher: ChannelWatcher.name, external_id: event.fetch("broadcaster_user_id"))
        return unless watch

        observation = observation(type, event)
        return unless observation

        Ops::Integrations::Twitch::Streams::Transition.call(watch:, observation:)
      rescue Error => error
        Rails.logger.warn("Integrations: Twitch #{type} for channel #{event["broadcaster_user_id"]} failed, the stream reconcile catches up: #{error.class}: #{error.message}")
      end

      private

      def observation(type, event)
        case type
        when "stream.online" then online(event)
        when "stream.offline" then Offline.new
        when "channel.update" then ChannelUpdate.from_event(event)
        end
      end

      def online(event)
        channel = Channels.new.for([event.fetch("broadcaster_user_id")]).first
        Live.from_online(event, channel) if channel
      end
    end
  end
end
