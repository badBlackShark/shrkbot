# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module Channels
      class DisablePlugins < ApplicationOperation
        self.transactional = false

        receives :server_configuration, :channel_id, :bot

        def call
          disabled = PluginCatalog.channel_backed.filter_map { |definition| disable_if_uses_channel(definition) }
          disabled.each { |plugin| notify_owner(plugin) }
          ok(disabled)
        end

        private

        def disable_if_uses_channel(definition)
          setting = server_configuration.public_send(definition.channel_setting)
          return unless setting&.channel_id == channel_id

          plugin = Plugin.find_by(key: definition.key)
          transaction do
            setting.update!(channel_id: nil)
            Plugins::Toggle.call(server_configuration: server_configuration, plugin:, enabled: false)
          end
          plugin
        end

        def notify_owner(plugin)
          OwnerNotifier.notify(
            bot: bot,
            message: "⚠️ **#{plugin.name}** was disabled because its configured channel was deleted. Reconfigure it to turn it back on."
          )
        end
      end
    end
  end
end
