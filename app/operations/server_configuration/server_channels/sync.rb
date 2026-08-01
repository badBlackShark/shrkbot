# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module ServerChannels
      class Sync < ApplicationOperation
        receives :server_configuration, :channels

        def call
          existing = server_configuration.server_channels.includes(:channel_overwrites).index_by(&:discord_id)
          channels.each { |data| sync_channel(data, existing) }
          server_configuration.server_channels.where.not(discord_id: channels.map { |c| c[:discord_id] }).destroy_all
          ok(server_configuration.server_channels.reload)
        end

        private

        def sync_channel(data, existing)
          channel = existing[data[:discord_id]] || server_configuration.server_channels.build(discord_id: data[:discord_id])
          created = channel.new_record?
          channel.update!(**Attributes.call(data))
          ChannelOverwrites::Replace.call(
            server_channel: channel,
            overwrites: data[:overwrites],
            created:
          )
        end
      end
    end
  end
end
