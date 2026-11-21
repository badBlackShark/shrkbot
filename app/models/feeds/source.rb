# frozen_string_literal: true

module Feeds
  class Source
    def self.post_type(event_type)
      event_type
    end

    def self.announced_types
      event_types
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
