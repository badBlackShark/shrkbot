# frozen_string_literal: true

module Feeds
  PLUGIN_KEY = :feeds
  SOURCE_PLUGINS = {"Integrations::Steam::NewsWatcher" => :steam_news}.freeze
  EVENT_TYPES = %w[
    Integrations::Steam::PatchNotesPublished
    Integrations::Steam::AnnouncementPublished
    Integrations::Steam::ArticlePublished
  ].freeze
end
