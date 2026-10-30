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

    def self.settings_association
      :steam_settings
    end

    def self.role_id_for(subscription, _event_type)
      subscription.settings.role_id
    end

    def self.accepts?(subscription, event)
      subscription.settings.accepts_language?(event.language)
    end
  end
end
