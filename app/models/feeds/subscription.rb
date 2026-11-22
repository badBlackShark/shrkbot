# frozen_string_literal: true

module Feeds
  class Subscription < ApplicationRecord
    self.table_name = "feed_subscriptions"

    belongs_to :server_configuration
    belongs_to :watch, class_name: "Integrations::Watch"
    has_many :subscribed_events, dependent: :delete_all, autosave: true
    has_many :posts, dependent: :delete_all
    has_one :steam_settings, class_name: "Feeds::Steam::Settings", dependent: :delete, autosave: true
    has_one :twitch_settings, class_name: "Feeds::Twitch::Settings", dependent: :delete, autosave: true
    has_one :twitch_category_settings, class_name: "Feeds::TwitchCategory::Settings", dependent: :delete, autosave: true

    validates :channel_id, presence: true
    validates :watch_id, uniqueness: {scope: :server_configuration_id}

    def follow(event_type, **choices)
      subscribed_events.build(event_type:).tap do |event|
        event.apply(**choices)
      end
    end

    def channel_for(event_type)
      subscribed_events.where(event_type: source.post_type(event_type)).pick(:channel_id) || channel_id
    end

    def self.posting_to(channel_id, event_type)
      joins(:subscribed_events)
        .where(feed_subscribed_events: {event_type:})
        .where("COALESCE(feed_subscribed_events.channel_id, feed_subscriptions.channel_id) = ?", channel_id)
    end

    def source
      Feeds.source_for_watcher(watch.watcher)
    end

    def settings
      public_send(source.settings_association)
    end

    def build_settings(attributes = {})
      association(source.settings_association).build(attributes)
    end

    def self.for_source(source)
      where(watch_id: Integrations::Watch.where(watcher: source.watchers).select(:id))
    end

    def self.at_cap?(server_configuration, source)
      server_configuration.feed_subscriptions.for_source(source).count >= source.max_follows
    end

    def self.cap_message(source)
      I18n.t("operations.feeds.subscriptions.cap.#{source.key}", max: source.max_follows)
    end

    def self.demanding(event_types)
      active.where(id: SubscribedEvent.where(event_type: event_types).select(:subscription_id))
    end

    def self.viewer_floors(watch_ids)
      Feeds.sources.flat_map { |source| source.viewer_floors(watch_ids) }
    end

    def self.demanded_types(watch_ids)
      active
        .where(watch_id: watch_ids)
        .joins(:subscribed_events)
        .distinct
        .pluck(:watch_id, "feed_subscribed_events.event_type")
    end

    def self.active
      base = where(server_configuration_id: ServerConfiguration.real.select(:id))

      Feeds.sources.map { |source|
        base.for_source(source).where(
          server_configuration_id: PluginActivation.enabled_for(source.plugin_key).select(:server_configuration_id)
        )
      }.reduce(:or)
    end
  end
end
