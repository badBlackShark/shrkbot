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
        source = ::Feeds.source(@plugin_key)

        @config.feed_subscriptions
          .for_source(source)
          .joins(:watch)
          .includes(:watch, :subscribed_events, source.settings_association)
          .order("integration_watches.name", :id)
      end
    end
  end
end
