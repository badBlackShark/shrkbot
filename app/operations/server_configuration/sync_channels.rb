module Ops
  module ServerConfiguration
    class SyncChannels < ApplicationOperation
      def initialize(server_configuration:, channels:)
        @server_configuration = server_configuration
        @channels = channels
      end

      def call
        transaction do
          @channels.each { |data| sync_channel(data) }
          @server_configuration.server_channels.where.not(discord_id: @channels.map { |c| c[:discord_id] }).destroy_all
        end
        ok(@server_configuration.server_channels.reload)
      end

      private

      def sync_channel(data)
        channel = @server_configuration.server_channels.find_or_initialize_by(discord_id: data[:discord_id])
        channel.update!(name: data[:name], channel_type: data[:channel_type])
        sync_overwrites(channel, data[:overwrites])
      end

      def sync_overwrites(channel, overwrites)
        overwrites.each do |data|
          overwrite = channel.channel_overwrites.find_or_initialize_by(target_id: data[:target_id])
          overwrite.update!(target_type: data[:target_type], allow: data[:allow], deny: data[:deny])
        end
        channel.channel_overwrites.where.not(target_id: overwrites.map { |o| o[:target_id] }).delete_all
      end
    end
  end
end
