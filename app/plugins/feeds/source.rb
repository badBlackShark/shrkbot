# frozen_string_literal: true

module Feeds
  class Source
    def self.key
      plugin_key
    end

    def self.post_type(event_type)
      event_type
    end

    def self.announced_types
      event_types
    end

    def self.max_follows
      Subscription::MAX_PER_SOURCE
    end

    def self.postable?(_subscription, _event)
      true
    end

    def self.subscriptions_for(event)
      Subscription.for_source(self).where(watch_id: event.watch_id)
    end

    def self.role_override_for(_subscription, _event_type)
    end

    def self.retract?(_subscription, _event)
      false
    end

    def self.revive?(_subscription, _event)
      false
    end
  end
end
