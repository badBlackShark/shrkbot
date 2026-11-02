# frozen_string_literal: true

class AllowTwitchStreamStartedOnFeedSubscribedEvents < ActiveRecord::Migration[8.1]
  STEAM_TYPES = "'Integrations::Steam::PatchNotesPublished', 'Integrations::Steam::AnnouncementPublished', 'Integrations::Steam::ArticlePublished'"

  def up
    remove_check_constraint :feed_subscribed_events, name: "feed_subscribed_events_event_type"
    add_check_constraint :feed_subscribed_events,
      "event_type IN (#{STEAM_TYPES}, 'Integrations::Twitch::StreamStarted')",
      name: "feed_subscribed_events_event_type",
      validate: false
  end

  def down
    remove_check_constraint :feed_subscribed_events, name: "feed_subscribed_events_event_type"
    add_check_constraint :feed_subscribed_events,
      "event_type IN (#{STEAM_TYPES})",
      name: "feed_subscribed_events_event_type"
  end
end
