# frozen_string_literal: true

module Feeds
  PLUGIN_KEY = :feeds
  SOURCE_PLUGINS = {"Integrations::Steam::NewsWatcher" => :steam_news}.freeze
  EVENT_TYPES_BY_SOURCE = {
    steam_news: %w[
      Integrations::Steam::PatchNotesPublished
      Integrations::Steam::AnnouncementPublished
      Integrations::Steam::ArticlePublished
    ]
  }.freeze
  EVENT_TYPES = EVENT_TYPES_BY_SOURCE.values.flatten.freeze
  DEFAULT_EVENT_TYPES_BY_SOURCE = {
    steam_news: %w[
      Integrations::Steam::PatchNotesPublished
      Integrations::Steam::AnnouncementPublished
    ]
  }.freeze

  def self.event_key(event_type)
    event_type.demodulize.underscore
  end
end
