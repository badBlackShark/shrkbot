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
          scopes = ::Feeds.sources_for_plugin(plugin_key).map { |source| server_configuration.feed_subscriptions.for_source(source) }
          scopes.reduce(:or)
        end
      end
    end
  end
end
