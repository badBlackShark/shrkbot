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

        def feeds_group?
          PluginCatalog.sub_plugin_keys(plugin_key).intersect?(::Feeds::SOURCE_PLUGINS.values)
        end

        def subscriptions
          all = server_configuration.feed_subscriptions
          return all if feeds_group?

          watchers = ::Feeds.watchers_for(plugin_key)
          all.where(watch_id: ::Integrations::Watch.where(watcher: watchers).select(:id)) if watchers.any?
        end
      end
    end
  end
end
