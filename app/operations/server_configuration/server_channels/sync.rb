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
          channel.update!(
            name: data[:name],
            channel_type: data[:channel_type],
            position: data[:position],
            parent_id: data[:parent_id]
          )
          sync_overwrites(channel, data[:overwrites])
        end

        def sync_overwrites(channel, overwrites)
          existing = channel.channel_overwrites.loaded? ? channel.channel_overwrites.index_by(&:target_id) : {}
          overwrites.each do |data|
            overwrite = existing[data[:target_id]] || channel.channel_overwrites.build(target_id: data[:target_id])
            overwrite.update!(target_type: data[:target_type], allow: data[:allow], deny: data[:deny])
          end
          channel.channel_overwrites.where.not(target_id: overwrites.map { |o| o[:target_id] }).delete_all if existing.any?
        end
      end
    end
  end
end
