# frozen_string_literal: true

module Feeds
  module Twitch
    POSTED_AS = {
      "Integrations::Twitch::StreamUpdated" => "Integrations::Twitch::StreamStarted",
      "Integrations::Twitch::StreamSampled" => "Integrations::Twitch::StreamStarted",
      "Integrations::Twitch::StreamEnded" => "Integrations::Twitch::StreamStarted"
    }.freeze

    def self.plugin_key
      :twitch
    end

    def self.watchers
      %w[Integrations::Twitch::ChannelWatcher]
    end

    def self.event_types
      %w[
        Integrations::Twitch::StreamStarted
        Integrations::Twitch::HighlightPublished
        Integrations::Twitch::UploadPublished
        Integrations::Twitch::FeaturedClipPublished
        Integrations::Twitch::ClipCreated
      ]
    end

    def self.default_event_types
      %w[Integrations::Twitch::StreamStarted Integrations::Twitch::HighlightPublished]
    end

    def self.post_type(event_type)
      POSTED_AS.fetch(event_type, event_type)
    end

    def self.announced_types
      event_types + %w[Integrations::Twitch::StreamUpdated]
    end

    def self.template_tokens
      %w[streamer category title clipper]
    end

    def self.settings_association
      :twitch_settings
    end

    def self.role_id_for(subscription, event_type)
      subscription.settings.role_id_for(event_type)
    end

    def self.accepts?(subscription, event)
      return true if event.is_a?(Integrations::Twitch::VideoEvent)

      subscription.settings.accepts_category?(event.category_id)
    end

    def self.retract?(subscription, event)
      event.is_a?(Integrations::Twitch::StreamEnded) && subscription.settings.live_end_mode == "delete"
    end

    def self.announcement(event:, subscription:)
      case event
      when Integrations::Twitch::StreamEnded then Ending.announcement(event:, subscription:)
      when Integrations::Twitch::VideoEvent then VideoAnnouncement.new(event:, subscription:)
      when Integrations::Twitch::ClipEvent then ClipAnnouncement.new(event:, subscription:, category: GameLookup.find(event.category_id))
      else Announcement.new(event:, subscription:, image_url: LiveImage.for(event))
      end
    end
  end
end
