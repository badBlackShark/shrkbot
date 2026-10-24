# frozen_string_literal: true

module Feeds
  class SubscriptionPaths
    def self.new_for(server_configuration, plugin_key)
      helpers.public_send("new_server_#{plugin_key}_subscription_path", server_configuration.discord_id)
    end

    def self.edit_for(subscription)
      helpers.public_send("edit_server_#{plugin_key(subscription)}_subscription_path", subscription.server_configuration.discord_id, subscription)
    end

    def self.for(subscription)
      helpers.public_send("server_#{plugin_key(subscription)}_subscription_path", subscription.server_configuration.discord_id, subscription)
    end

    private_class_method def self.plugin_key(subscription)
      SOURCE_PLUGINS.fetch(subscription.watch.watcher)
    end

    private_class_method def self.helpers
      Rails.application.routes.url_helpers
    end
  end
end
