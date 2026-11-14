# frozen_string_literal: true

module Feeds
  module Twitch
    POSTED_AS = {
      "Integrations::Twitch::StreamUpdated" => "Integrations::Twitch::StreamStarted",
      "Integrations::Twitch::StreamSampled" => "Integrations::Twitch::StreamStarted",
      "Integrations::Twitch::StreamEnded" => "Integrations::Twitch::StreamStarted"
    }.freeze
    NOTIFICATIONS = {
      "Integrations::Twitch::StreamStarted" => "{streamer} is live: {title}",
      "Integrations::Twitch::HighlightPublished" => "{streamer} posted a highlight: {title}",
      "Integrations::Twitch::UploadPublished" => "{streamer} uploaded a video: {title}",
      "Integrations::Twitch::FeaturedClipPublished" => "New featured clip from {streamer}: {title}",
      "Integrations::Twitch::ClipCreated" => "New clip from {streamer}: {title}"
    }.freeze

    TOKENS = {
      "Integrations::Twitch::StreamStarted" => %w[streamer category title],
      "Integrations::Twitch::HighlightPublished" => %w[streamer title],
      "Integrations::Twitch::UploadPublished" => %w[streamer title],
      "Integrations::Twitch::FeaturedClipPublished" => %w[streamer category title clipper],
      "Integrations::Twitch::ClipCreated" => %w[streamer category title clipper]
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

    def self.post_type(event_type)
      POSTED_AS.fetch(event_type, event_type)
    end

    def self.announced_types
      event_types + %w[Integrations::Twitch::StreamUpdated]
    end

    def self.template_tokens
      TOKENS.values.flatten.uniq
    end

    def self.tokens_for(event_type)
      TOKENS.fetch(event_type)
    end

    def self.notification_tokens
      template_tokens
    end

    def self.default_notification(event_type)
      NOTIFICATIONS[event_type]
    end

    def self.settings_association
      :twitch_settings
    end

    def self.lookup_param
      :channel
    end

    def self.settings_params
      [*scalar_settings, {categories: []}]
    end

    def self.settings_from(permitted)
      permitted.slice(*scalar_settings).to_h.symbolize_keys.merge(categories: CategoryValue.parse_all(permitted[:categories]))
    end

    def self.scalar_settings
      [*Settings::ROLE_COLUMNS.values, :live_end_mode, :show_viewers, :switched_away]
    end
    private_class_method :scalar_settings

    def self.role_id_for(subscription, event_type)
      subscription.settings.role_id_for(event_type)
    end

    def self.accepts?(subscription, event)
      return true if event.is_a?(Integrations::Twitch::VideoEvent)

      subscription.settings.accepts_category?(event.category_id)
    end

    def self.retract?(subscription, event)
      return subscription.settings.live_end_mode == "delete" if event.is_a?(Integrations::Twitch::StreamEnded)

      switched_away?(subscription, event) && subscription.settings.switched_away == "delete"
    end

    def self.revive?(subscription, event)
      live?(event) && accepts?(subscription, event)
    end

    def self.live?(event)
      event.is_a?(Integrations::Twitch::StreamEvent) && !event.is_a?(Integrations::Twitch::StreamEnded)
    end
    private_class_method :live?

    def self.switched_away?(subscription, event)
      live?(event) && !accepts?(subscription, event)
    end
    private_class_method :switched_away?

    def self.announcement(event:, subscription:)
      return SwitchedAnnouncement.new(event:, subscription:) if switched_away?(subscription, event)

      case event
      when Integrations::Twitch::StreamEnded then Ending.announcement(event:, subscription:)
      when Integrations::Twitch::VideoEvent then VideoAnnouncement.new(event:, subscription:)
      when Integrations::Twitch::ClipEvent then ClipAnnouncement.new(event:, subscription:, category: GameLookup.find(event.category_id))
      else Announcement.new(event:, subscription:, image_url: LiveImage.for(event))
      end
    end
  end
end
