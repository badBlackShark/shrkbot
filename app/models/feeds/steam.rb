# frozen_string_literal: true

module Feeds
  module Steam
    NOTIFICATIONS = {
      "Integrations::Steam::PatchNotesPublished" => "{game} · Patch notes: {title}",
      "Integrations::Steam::AnnouncementPublished" => "{game} · Announcement: {title}",
      "Integrations::Steam::ArticlePublished" => "{game} · {feed}: {title}"
    }.freeze

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

    def self.post_type(event_type)
      event_type
    end

    def self.announced_types
      event_types
    end

    def self.template_tokens
      %w[game author feed]
    end

    def self.notification_tokens
      template_tokens + %w[title]
    end

    def self.default_notification(event_type)
      NOTIFICATIONS[event_type]
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

    def self.retract?(_subscription, _event)
      false
    end

    def self.revive?(_subscription, _event)
      false
    end

    def self.announcement(event:, subscription:)
      Announcement.new(event:, subscription:, thumbnail: Thumbnail.for(event.watch))
    end
  end
end
