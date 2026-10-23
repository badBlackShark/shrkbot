# frozen_string_literal: true

module Feeds
  class StoryPick
    def initialize(subscription:, event:)
      @subscription = subscription
      @event = event
    end

    def best?
      best == event
    end

    private

    attr_reader :subscription, :event

    def best
      candidates.min_by { |candidate| [candidate.is_a?(Integrations::Steam::ArticlePublished) ? 1 : 0, candidate.occurred_at, candidate.id] }
    end

    def candidates
      Integrations::Event
        .where(watch_id: event.watch_id, type: subscription.subscribed_events.select(:event_type))
        .where("payload ->> 'story_key' = ?", event.story_key)
    end
  end
end
