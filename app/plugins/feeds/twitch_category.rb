# frozen_string_literal: true

module Feeds
  class TwitchCategory < Twitch
    MAX_FOLLOWS = 10
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

    def self.settings_params
      [*SCALAR_SETTINGS, {languages: [], excluded_channels: []}]
    end

    def self.settings_from(permitted)
      permitted.slice(*SCALAR_SETTINGS).to_h.symbolize_keys.merge(
        languages: Array(permitted[:languages]).compact_blank,
        excluded_channels: Array(permitted[:excluded_channels])
      )
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
      return Subscription.none unless event.category_id

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
