# frozen_string_literal: true

module Feeds
  SOURCE_PLUGINS = {"Integrations::Steam::NewsWatcher" => :steam}.freeze
  EVENT_TYPES_BY_SOURCE = {
    steam: %w[
      Integrations::Steam::PatchNotesPublished
      Integrations::Steam::AnnouncementPublished
      Integrations::Steam::ArticlePublished
    ]
  }.freeze
  EVENT_TYPES = EVENT_TYPES_BY_SOURCE.values.flatten.freeze
  DEFAULT_EVENT_TYPES_BY_SOURCE = {
    steam: %w[
      Integrations::Steam::PatchNotesPublished
      Integrations::Steam::AnnouncementPublished
    ]
  }.freeze

  def self.watchers_for(plugin_key)
    SOURCE_PLUGINS.select { |_, key| key == plugin_key }.keys
  end

  def self.event_key(event_type)
    event_type.demodulize.underscore
  end
end
