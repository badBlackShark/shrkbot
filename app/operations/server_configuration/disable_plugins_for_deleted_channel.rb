module Ops
  module ServerConfiguration
    class DisablePluginsForDeletedChannel < ApplicationOperation
      # Hardcoded until the plugin-metadata DSL (Roles phase) declares it.
      CHANNEL_BACKED = {logging: :logging_setting, welcomes: :welcome_settings, roles: :role_setting}.freeze

      def initialize(server_configuration:, channel_id:, bot:)
        @server_configuration = server_configuration
        @channel_id = channel_id
        @bot = bot
      end

      def call
        disabled = CHANNEL_BACKED.filter_map { |key, association| disable_if_uses_channel(key, association) }
        disabled.each { |plugin| notify_owner(plugin) }
        ok(disabled)
      end

      private

      def disable_if_uses_channel(plugin_key, association)
        setting = @server_configuration.public_send(association)
        return unless setting&.channel_id == @channel_id

        plugin = Plugin.find_by(key: plugin_key)
        transaction do
          setting.update!(channel_id: nil)
          TogglePlugin.call(server_configuration: @server_configuration, plugin:, enabled: false)
        end
        plugin
      end

      def notify_owner(plugin)
        OwnerNotifier.notify(
          bot: @bot,
          message: "⚠️ **#{plugin.name}** was disabled because its configured channel was deleted. Reconfigure it to turn it back on."
        )
      end
    end
  end
end
