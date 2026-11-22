# frozen_string_literal: true

module Ops
  module Notification
    module FeedPostFailure
      class Ensure < ApplicationOperation
        KIND = "feed_post_failed"

        receives :subscription, :channel_id

        def call
          return ok(nil) if already_reported?

          Ops::Notification::Create.call(
            server_configuration:,
            kind: KIND,
            data: {
              plugin_key: subscription.source.plugin_key.to_s,
              name: subscription.watch.name,
              channel_name:,
              subscription_id: subscription.id
            }
          )
        end

        private

        def already_reported?
          server_configuration.notifications.active.where(kind: KIND).where("data->>'subscription_id' = ?", subscription.id).exists?
        end

        def channel_name
          server_configuration.server_channels.find_by(discord_id: channel_id)&.name
        end

        def server_configuration
          subscription.server_configuration
        end
      end
    end
  end
end
