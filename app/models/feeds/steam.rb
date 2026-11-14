# frozen_string_literal: true

module Feeds
  class Steam < Source
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

    def self.template_tokens
      %w[game author feed]
    end

    def self.notification_tokens
      template_tokens + %w[title]
    end

    def self.default_notification(event_type)
      "{game} · #{Announcement::TYPE_LABELS.fetch(event_type, "{feed}")}: {title}"
    end

    def self.settings_association
      :steam_settings
    end

    def self.lookup_param
      :app
    end

    def self.settings_params
      [:role_id, :body_length, {languages: []}]
    end

    def self.settings_from(permitted)
      {role_id: permitted[:role_id], body_length: permitted[:body_length], languages: Array(permitted[:languages])}
    end

    def self.role_id_for(subscription, _event_type)
      subscription.settings.role_id
    end

    def self.accepts?(subscription, event)
      subscription.settings.accepts_language?(event.language)
    end

    def self.announcement(event:, subscription:)
      Announcement.new(event:, subscription:, thumbnail: Thumbnail.for(event.watch))
    end
  end
end
