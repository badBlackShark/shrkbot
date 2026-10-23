# frozen_string_literal: true

module Feeds
  class Subscription < ApplicationRecord
    BODY_LENGTHS = %w[preview full].freeze

    self.table_name = "feed_subscriptions"

    belongs_to :server_configuration
    belongs_to :watch, class_name: "Integrations::Watch"
    has_many :subscribed_events, dependent: :delete_all
    has_many :posts, dependent: :delete_all

    validates :body_length, inclusion: {in: BODY_LENGTHS}
    validates :channel_id, presence: true
    validates :watch_id, uniqueness: {scope: :server_configuration_id}

    def self.active
      base = where(server_configuration_id: ServerConfiguration.real.select(:id))
        .where(server_configuration_id: PluginActivation.enabled_for(PLUGIN_KEY).select(:server_configuration_id))

      SOURCE_PLUGINS.map { |watcher, key|
        base.where(
          watch_id: Integrations::Watch.where(watcher:).select(:id),
          server_configuration_id: PluginActivation.enabled_for(key).select(:server_configuration_id)
        )
      }.reduce(:or)
    end
  end
end
