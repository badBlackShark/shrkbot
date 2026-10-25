# frozen_string_literal: true

module Feeds
  GROUP_KEY = :integrations
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

  def self.event_key(event_type)
    event_type.demodulize.underscore
  end
end
