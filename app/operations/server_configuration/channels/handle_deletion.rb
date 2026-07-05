# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module Channels
      class HandleDeletion < ApplicationOperation
        self.transactional = false

        receives :server_configuration, :channel_id, :bot

        def call
          affected = PluginCatalog.channel_backed.filter_map { |definition| clear_if_uses_channel(definition) }
          affected.each { |plugin| notify_owner(plugin) }
          ok(affected)
        end

        private

        def clear_if_uses_channel(definition)
          setting = server_configuration.public_send(definition.channel_setting)
          return unless setting&.channel_id == channel_id

          plugin = Plugin.find_by(key: definition.key)
          channel_name = server_configuration.server_channels.find_by(discord_id: channel_id)&.name
          setting.update!(channel_id: nil)
          Ops::Notifications::Create.call(
            server_configuration:,
            kind: "channel_deleted",
            data: {plugin_key: definition.key.to_s, plugin_name: plugin.name, channel_name:}
          )
          plugin
        end

        def notify_owner(plugin)
          OwnerNotifier.notify(bot:, message: owner_message(plugin))
        end

        def owner_message(plugin)
          "⚠️ **#{plugin.name}**'s configured channel was deleted. Pick a new channel to keep it working.\n#{config_url(plugin)}"
        end

        def config_url(plugin)
          "#{BotConfig.server_config_url(server_configuration.discord_id)}/#{plugin.key}"
        end
      end
    end
  end
end
