# frozen_string_literal: true

module Feeds
  class TwitchCategory < Twitch
    MAX_FOLLOWS = 10
    LANGUAGES = %w[
      en de fr es it pt ru ja ko zh zh-hk ar bg ca cs da el fi hi hu id ms nl no pl ro sk sv th tl tr uk vi asl other
    ].freeze
    SCALAR_SETTINGS = %i[role_id min_viewers live_end_mode switched_away show_viewers show_preview_frame].freeze

    def self.key
      :twitch_category
    end

    def self.watchers
      %w[Integrations::Twitch::CategoryWatcher]
    end

    def self.event_types
      %w[Integrations::Twitch::StreamStarted]
    end

    def self.announced_types
      event_types + %w[Integrations::Twitch::StreamUpdated Integrations::Twitch::StreamSampled]
    end

    def self.settings_association
      :twitch_category_settings
    end

    def self.lookup_param
      :category
    end

    def self.lookup_reference(value)
      CategoryValue.parse(value)&.fetch("id") || value
    end

    def self.settings_params
      [*scalar_settings, {languages: [], excluded_channels: []}]
    end

    def self.scalar_settings
      SCALAR_SETTINGS
    end
    private_class_method :scalar_settings

    def self.list_settings(permitted)
      {
        languages: Array(permitted[:languages]).compact_blank,
        excluded_channels: Array(permitted[:excluded_channels])
      }
    end
    private_class_method :list_settings

    def self.role_override_for(_subscription, _event_type)
    end

    def self.viewer_floors(watch_ids)
      Subscription
        .active
        .for_source(self)
        .where(watch_id: watch_ids)
        .joins(:twitch_category_settings)
        .where("feed_twitch_category_settings.min_viewers > 0")
        .pluck(:watch_id, "feed_twitch_category_settings.min_viewers")
    end

    def self.max_follows
      MAX_FOLLOWS
    end

    def self.accepts?(subscription, event)
      event.category_id == subscription.watch.external_id
    end

    def self.postable?(subscription, event)
      subscription.settings.accepts_stream?(event) &&
        subscription.settings.meets_floor?(event) &&
        !direct_follow_owns?(subscription, event)
    end

    def self.subscriptions_for(event)
      Subscription.for_source(self).where(
        watch_id: Integrations::Watch.where(watcher: watchers, external_id: event.category_id).select(:id)
      )
    end

    def self.direct_follow_owns?(subscription, event)
      direct = Subscription
        .demanding(%w[Integrations::Twitch::StreamStarted])
        .find_by(server_configuration_id: subscription.server_configuration_id, watch_id: event.watch_id)

      direct.present? && Twitch.accepts?(direct, event)
    end
    private_class_method :direct_follow_owns?
  end
end
