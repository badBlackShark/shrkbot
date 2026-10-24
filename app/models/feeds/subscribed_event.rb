# frozen_string_literal: true

module Feeds
  class SubscribedEvent < ApplicationRecord
    self.table_name = "feed_subscribed_events"

    attribute :subscribed_since, default: -> { Time.current }

    belongs_to :subscription

    validates :event_type, inclusion: {in: ::Feeds::EVENT_TYPES}, uniqueness: {scope: :subscription_id}
    validates :subscribed_since, presence: true
  end
end
