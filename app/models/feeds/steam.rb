# frozen_string_literal: true

module Feeds
  module Steam
    def self.plugin_key
      :steam
    end

    def self.watchers
      %w[Integrations::Steam::NewsWatcher]
    end

    def self.event_types
      %w[
        Integrations::Steam::PatchNotesPublished
        Integrations::Steam::AnnouncementPublished
        Integrations::Steam::ArticlePublished
      ]
    end

    def self.default_event_types
      %w[
        Integrations::Steam::PatchNotesPublished
        Integrations::Steam::AnnouncementPublished
      ]
    end

    def self.template_tokens
      %w[game author feed]
    end
  end
end
