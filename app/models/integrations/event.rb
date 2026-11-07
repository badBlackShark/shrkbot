# frozen_string_literal: true

module Integrations
  class Event < ApplicationRecord
    FRESHNESS_WINDOW = 48.hours

    self.table_name = "integration_events"

    class_attribute :secondary, default: false, instance_writer: false

    store_accessor :payload, :story_key

    belongs_to :watch

    validates :type, :subject_key, :occurred_at, :story_key, presence: true

    scope :undispatched, -> { where(dispatched_at: nil) }
    scope :in_story, ->(watch_id, story_key) { where(watch_id:).where("payload ->> 'story_key' = ?", story_key) }
    scope :stranded, -> {
      undispatched.where(created_at: FRESHNESS_WINDOW.ago...1.minute.ago, occurred_at: FRESHNESS_WINDOW.ago..)
    }

    def enrich
    end

    def expired?
      false
    end
  end
end
