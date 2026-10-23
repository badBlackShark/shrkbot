# frozen_string_literal: true

module Integrations
  module Bus
    mattr_reader :subscriptions, default: {}, instance_accessor: false

    class << self
      def subscribe(handler, to:)
        subscriptions[handler] = subscriptions.fetch(handler, []) | Array(to)
      end

      def handlers_for(event)
        subscriptions.select { |_handler, classes| classes.any? { |klass| event.is_a?(klass) } }.keys
      end
    end
  end
end
