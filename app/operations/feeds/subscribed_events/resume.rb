# frozen_string_literal: true

module Ops
  module Feeds
    module SubscribedEvents
      class Resume < ApplicationOperation
        receives :server_configuration, :plugin_key

        def call
          scope = subscriptions
          ::Feeds::SubscribedEvent.where(subscription_id: scope.select(:id)).update_all(subscribed_since: Time.current) if scope
          ok
        end

        private

        def subscriptions
          all = server_configuration.feed_subscriptions
          return all if plugin_key == ::Feeds::PLUGIN_KEY

          watcher = ::Feeds::SOURCE_PLUGINS.key(plugin_key)
          all.where(watch_id: ::Integrations::Watch.where(watcher:).select(:id)) if watcher
        end
      end
    end
  end
end
