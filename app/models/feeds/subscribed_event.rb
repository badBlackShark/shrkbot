# frozen_string_literal: true

module Feeds
  class SubscribedEvent < ApplicationRecord
    self.table_name = "feed_subscribed_events"

    attribute :subscribed_since, default: -> { Time.current }

    belongs_to :subscription

    validates :event_type, inclusion: {in: ->(event) { event.subscription.source.event_types }}, uniqueness: {scope: :subscription_id}
    validates :subscribed_since, presence: true

    def apply(template: nil, notification: nil, channel_id: nil)
      self.template = Templates.custom(template)
      self.notification_template = Templates.notification(notification, subscription.source.default_notification(event_type))
      self.channel_id = channel_id
    end
  end
end
