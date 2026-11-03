# frozen_string_literal: true

module Feeds
  module Twitch
    def self.plugin_key
      :twitch
    end

    def self.watchers
      %w[Integrations::Twitch::ChannelWatcher]
    end

    def self.event_types
      %w[Integrations::Twitch::StreamStarted]
    end

    def self.default_event_types
      event_types
    end

    def self.template_tokens
      %w[streamer category]
    end

    def self.settings_association
      :twitch_settings
    end

    def self.role_id_for(subscription, event_type)
      subscription.settings.role_id_for(event_type)
    end

    def self.accepts?(_subscription, _event)
      true
    end

    def self.announcement(event:, subscription:)
      Announcement.new(event:, subscription:, image_url: LiveImage.for(event))
    end
  end
end
