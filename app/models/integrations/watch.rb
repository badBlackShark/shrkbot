# frozen_string_literal: true

module Integrations
  class Watch < ApplicationRecord
    BROKEN_AFTER = 24.hours

    self.table_name = "integration_watches"

    class_attribute :demand_sources, default: []

    has_many :seen_items, dependent: :delete_all
    has_many :events, dependent: :delete_all

    validates :watcher, :name, presence: true
    validates :external_id, presence: true, uniqueness: {scope: :watcher}

    scope :broken, -> { where(failing_since: ..BROKEN_AFTER.ago) }
    scope :unreported, -> {
      where(broken_reported_at: nil)
        .or(where(arel_table[:broken_reported_at].lt(arel_table[:failing_since])))
    }
    scope :due, -> {
      where(failing_since: nil)
        .or(where(failing_since: BROKEN_AFTER.ago..))
        .or(where(polled_at: ...Time.current.beginning_of_hour))
    }

    def self.demanded_by(source)
      self.demand_sources |= [source]
    end

    def self.demanded
      demand_matching(:active)
    end

    def self.referenced
      demand_matching(:all)
    end

    def self.demand_matching(kind)
      demand_sources.map { |source| where(id: source.public_send(kind).select(:watch_id)) }.reduce(:or) || none
    end
    private_class_method :demand_matching

    def watcher_class
      watcher.constantize
    end
  end
end
