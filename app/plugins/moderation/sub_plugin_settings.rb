# frozen_string_literal: true

module Moderation
  module SubPluginSettings
    extend ActiveSupport::Concern

    class_methods do
      def active_settings(discord_id, plugin_key)
        config = ServerConfiguration.find_by(discord_id:)
        return unless config
        return unless config.enabled_plugin_keys.include?(plugin_key)

        yield config
      end
    end
  end
end
