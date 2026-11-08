# frozen_string_literal: true

class AllowTwitchMediaOnFeedSubscribedEvents < ActiveRecord::Migration[8.1]
  STEAM_TYPES = "'Integrations::Steam::PatchNotesPublished', 'Integrations::Steam::AnnouncementPublished', 'Integrations::Steam::ArticlePublished'"
  STREAM_STARTED = "'Integrations::Twitch::StreamStarted'"
  MEDIA_TYPES = "'Integrations::Twitch::HighlightPublished', 'Integrations::Twitch::UploadPublished', 'Integrations::Twitch::FeaturedClipPublished', 'Integrations::Twitch::ClipCreated'"

  def up
    remove_check_constraint :feed_subscribed_events, name: "feed_subscribed_events_event_type"
    add_check_constraint :feed_subscribed_events,
      "event_type IN (#{STEAM_TYPES}, #{STREAM_STARTED}, #{MEDIA_TYPES})",
      name: "feed_subscribed_events_event_type",
      validate: false
  end

  def down
    remove_check_constraint :feed_subscribed_events, name: "feed_subscribed_events_event_type"
    add_check_constraint :feed_subscribed_events,
      "event_type IN (#{STEAM_TYPES}, #{STREAM_STARTED})",
      name: "feed_subscribed_events_event_type"
  end
end
