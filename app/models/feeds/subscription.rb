# frozen_string_literal: true

module Feeds
  class Subscription < ApplicationRecord
    BODY_LENGTHS = %w[preview full].freeze
    MAX_PER_SERVER = 25

    self.table_name = "feed_subscriptions"

    belongs_to :server_configuration
    belongs_to :watch, class_name: "Integrations::Watch"
    has_many :subscribed_events, dependent: :delete_all, autosave: true
    has_many :posts, dependent: :delete_all

    validates :body_length, inclusion: {in: BODY_LENGTHS}
    validates :channel_id, presence: true
    validates :watch_id, uniqueness: {scope: :server_configuration_id}
    validate :languages_supported

    def follow(event_type, text)
      subscribed_events.build(event_type:, template: Templates.custom(text))
    end

    def accepts_language?(language)
      languages.empty? || language.nil? || languages.include?(language)
    end

    def plugin_key
      SOURCE_PLUGINS.fetch(watch.watcher)
    end

    def source_event_types
      EVENT_TYPES_BY_SOURCE.fetch(plugin_key)
    end

    def self.at_cap?(server_configuration)
      server_configuration.feed_subscriptions.count >= MAX_PER_SERVER
    end

    def self.active
      base = where(server_configuration_id: ServerConfiguration.real.select(:id))

      SOURCE_PLUGINS.map { |watcher, key|
        base.where(
          watch_id: Integrations::Watch.where(watcher:).select(:id),
          server_configuration_id: PluginActivation.enabled_for(key).select(:server_configuration_id)
        ).where(
          server_configuration_id: PluginActivation.enabled_for(PluginCatalog.find(key).parent).select(:server_configuration_id)
        )
      }.reduce(:or)
    end

    private

    def languages_supported
      errors.add(:languages, :inclusion) unless (languages - Integrations::Language::CODES).empty?
    end
  end
end
