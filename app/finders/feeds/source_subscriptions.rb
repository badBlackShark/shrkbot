# frozen_string_literal: true

module Finders
  module Feeds
    class SourceSubscriptions
      def self.call(server_configuration:, plugin_key:)
        new(server_configuration:, plugin_key:).call
      end

      def initialize(server_configuration:, plugin_key:)
        @config = server_configuration
        @plugin_key = plugin_key
      end

      def call
        @config.feed_subscriptions
          .joins(:watch)
          .where(integration_watches: {watcher: ::Feeds.watchers_for(@plugin_key)})
          .includes(:watch, :subscribed_events)
          .order("integration_watches.name", :id)
      end
    end
  end
end
