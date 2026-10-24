# frozen_string_literal: true

class ValidateEventTypeCheckOnFeedSubscribedEvents < ActiveRecord::Migration[8.1]
  def change
    validate_check_constraint :feed_subscribed_events, name: "feed_subscribed_events_event_type"
  end
end
