# frozen_string_literal: true

module Feeds
  class StoryPick
    def initialize(subscription:, event:)
      @subscription = subscription
      @event = event
    end

    def eligible?
      eligible_copy?(event)
    end

    def best?
      best == event
    end

    private

    attr_reader :subscription, :event

    def best
      candidates
        .select { |candidate| eligible_copy?(candidate) }
        .min_by { |candidate| [candidate.secondary ? 1 : 0, candidate.occurred_at, candidate.id] }
    end

    def eligible_copy?(copy)
      since = followed_since[copy.type]
      since.present? && copy.occurred_at >= since && subscription.accepts_language?(copy.language)
    end

    def followed_since
      @followed_since ||= subscription.subscribed_events.pluck(:event_type, :subscribed_since).to_h
    end

    def candidates
      Integrations::Event
        .where(watch_id: event.watch_id, type: followed_since.keys)
        .where("payload ->> 'story_key' = ?", event.story_key)
        .select(:id, :type, :occurred_at, "jsonb_build_object('language', payload -> 'language') AS payload")
    end
  end
end
