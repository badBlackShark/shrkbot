# frozen_string_literal: true

module Feeds
  class Subscription < ApplicationRecord
    BODY_LENGTHS = %w[preview full].freeze

    self.table_name = "feed_subscriptions"

    belongs_to :server_configuration
    belongs_to :watch, class_name: "Integrations::Watch"
    has_many :subscribed_events, dependent: :delete_all

    validates :body_length, inclusion: {in: BODY_LENGTHS}
    validates :channel_id, presence: true
    validates :watch_id, uniqueness: {scope: :server_configuration_id}

    def self.active
      sources = SOURCE_PLUGINS.map { |watcher, key|
        unscoped.joins(:watch).where(integration_watches: {watcher:}).where(server_configuration_id: enabled(key))
      }.reduce(:or)

      joins(:watch)
        .where(server_configuration_id: ServerConfiguration.real.select(:id))
        .where(server_configuration_id: enabled(PLUGIN_KEY))
        .and(sources)
    end

    def self.enabled(key)
      PluginActivation.joins(:plugin).where(enabled: true, plugins: {key:}).select(:server_configuration_id)
    end
    private_class_method :enabled
  end
end
