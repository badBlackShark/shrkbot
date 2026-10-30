# frozen_string_literal: true

module Feeds
  class Subscription < ApplicationRecord
    MAX_PER_SERVER = 25

    self.table_name = "feed_subscriptions"

    belongs_to :server_configuration
    belongs_to :watch, class_name: "Integrations::Watch"
    has_many :subscribed_events, dependent: :delete_all, autosave: true
    has_many :posts, dependent: :delete_all
    has_one :steam_settings, class_name: "Feeds::Steam::Settings", dependent: :delete, autosave: true

    validates :channel_id, presence: true
    validates :watch_id, uniqueness: {scope: :server_configuration_id}

    def follow(event_type, text)
      subscribed_events.build(event_type:, template: Templates.custom(text))
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

    def self.at_cap?(server_configuration)
      server_configuration.feed_subscriptions.count >= MAX_PER_SERVER
    end

    def self.active
      base = where(server_configuration_id: ServerConfiguration.real.select(:id))

      Feeds.sources.map { |source|
        base.where(
          watch_id: Integrations::Watch.where(watcher: source.watchers).select(:id),
          server_configuration_id: PluginActivation.enabled_for(source.plugin_key).select(:server_configuration_id)
        ).where(
          server_configuration_id: PluginActivation.enabled_for(PluginCatalog.find(source.plugin_key).parent).select(:server_configuration_id)
        )
      }.reduce(:or)
    end
  end
end
