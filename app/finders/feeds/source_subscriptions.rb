# frozen_string_literal: true

module Finders
  module Feeds
    class SourceSubscriptions
      def self.call(server_configuration:, source:)
        new(server_configuration:, source:).call
      end

      def initialize(server_configuration:, source:)
        @config = server_configuration
        @source = source
      end

      def call
        @config.feed_subscriptions
          .for_source(@source)
          .joins(:watch)
          .includes(:watch, :subscribed_events, @source.settings_association)
          .order("integration_watches.name", :id)
      end
    end
  end
end
