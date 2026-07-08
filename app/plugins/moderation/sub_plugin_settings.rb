# frozen_string_literal: true

module Moderation
  module SubPluginSettings
    extend ActiveSupport::Concern

    class_methods do
      def active_group_settings(discord_id, plugin_key)
        config = ServerConfiguration.find_by(discord_id:)
        return unless config

        enabled = config.plugins.enabled
        return unless enabled.exists?(key: :moderation) && enabled.exists?(key: plugin_key)

        yield config
      end
    end
  end
end
