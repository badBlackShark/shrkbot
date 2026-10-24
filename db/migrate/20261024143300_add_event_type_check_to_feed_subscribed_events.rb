# frozen_string_literal: true

class AddEventTypeCheckToFeedSubscribedEvents < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :feed_subscribed_events,
      "event_type IN ('Integrations::Steam::PatchNotesPublished', 'Integrations::Steam::AnnouncementPublished', 'Integrations::Steam::ArticlePublished')",
      name: "feed_subscribed_events_event_type",
      validate: false
  end
end
