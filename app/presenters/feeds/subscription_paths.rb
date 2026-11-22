# frozen_string_literal: true

module Feeds
  class SubscriptionPaths
    def self.plugin_for(server_configuration, source)
      path = PluginPaths.for(server_configuration, source.plugin_key)
      return path if Feeds.sources_for_plugin(source.plugin_key).one?

      "#{path}?#{{tab: source.key}.to_query}"
    end

    def self.new_for(server_configuration, source)
      helpers.public_send("new_server_#{source.key}_subscription_path", server_configuration.discord_id)
    end

    def self.collection_for(server_configuration, source)
      helpers.public_send("server_#{source.key}_subscriptions_path", server_configuration.discord_id)
    end

    def self.edit_for(subscription)
      helpers.public_send("edit_server_#{subscription.source.key}_subscription_path", subscription.server_configuration.discord_id, subscription)
    end

    def self.for(subscription)
      helpers.public_send("server_#{subscription.source.key}_subscription_path", subscription.server_configuration.discord_id, subscription)
    end

    def self.volume_for(subscription)
      helpers.public_send("server_#{subscription.source.key}_volume_path", subscription.server_configuration.discord_id, app: subscription.watch.external_id)
    end

    private_class_method def self.helpers
      Rails.application.routes.url_helpers
    end
  end
end
