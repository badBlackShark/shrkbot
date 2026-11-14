# frozen_string_literal: true

module Feeds
  class Source
    def self.post_type(event_type)
      event_type
    end

    def self.announced_types
      event_types
    end

    def self.notification_tokens
      template_tokens
    end

    def self.tokens_for(_event_type)
      notification_tokens
    end

    def self.retract?(_subscription, _event)
      false
    end

    def self.revive?(_subscription, _event)
      false
    end
  end
end
