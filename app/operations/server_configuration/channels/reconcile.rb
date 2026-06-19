module Ops
  module ServerConfiguration
    module Channels
      class Reconcile < ApplicationOperation
        self.transactional = false

        receives :server_configuration, :bot

        def execute
          existing = server_configuration.server_channels.pluck(:discord_id)
          stale = stale_channel_ids(existing)
          stale.each do |channel_id|
            DisablePlugins.call(server_configuration: server_configuration, channel_id:, bot: bot)
          end
          ok(stale)
        end

        private

        def stale_channel_ids(existing)
          PluginCatalog.channel_backed.filter_map do |definition|
            channel_id = server_configuration.public_send(definition.channel_setting)&.channel_id
            channel_id if channel_id && existing.exclude?(channel_id)
          end.uniq
        end
      end
    end
  end
end
