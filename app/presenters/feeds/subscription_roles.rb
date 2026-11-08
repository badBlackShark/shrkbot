# frozen_string_literal: true

module Feeds
  class SubscriptionRoles
    def initialize(subscription)
      @subscription = subscription
    end

    def shared?
      by_type.values.uniq.size <= 1
    end

    def shared
      by_type.values.first
    end

    def for(event_type)
      by_type[event_type]
    end

    private

    def by_type
      @by_type ||= event_types.to_h { |event_type| [event_type, source.role_id_for(@subscription, event_type)] }
    end

    def event_types
      @subscription.subscribed_events.map(&:event_type).presence || source.event_types
    end

    def source
      @subscription.source
    end
  end
end
