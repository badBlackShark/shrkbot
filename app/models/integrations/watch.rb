# frozen_string_literal: true

module Integrations
  class Watch < ApplicationRecord
    BROKEN_AFTER = 24.hours
    BROKEN_RETRY_INTERVAL = 1.hour

    self.table_name = "integration_watches"

    has_many :seen_items, dependent: :delete_all
    has_many :events, dependent: :delete_all

    validates :watcher, :name, presence: true
    validates :external_id, presence: true, uniqueness: {scope: :watcher}

    scope :broken, -> { where(failing_since: ..BROKEN_AFTER.ago) }
    scope :due, -> {
      where(failing_since: nil)
        .or(where(failing_since: BROKEN_AFTER.ago..))
        .or(where(polled_at: ..BROKEN_RETRY_INTERVAL.ago))
    }

    def watcher_class
      watcher.constantize
    end
  end
end
