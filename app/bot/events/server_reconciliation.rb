# frozen_string_literal: true

module Bot
  class ServerReconciliation < BaseEvent
    on :ready

    def handle
      stale_configurations.each do |config|
        next if Discord::GuildMembership.member?(config.discord_id)

        Ops::ServerConfiguration::Destroy.call(server_configuration: config)
      end
    end

    private

    def stale_configurations
      ::ServerConfiguration.where.not(discord_id: event.bot.servers.keys).select do |config|
        on_this_shard?(config.discord_id)
      end
    end

    def on_this_shard?(discord_id)
      shard_id, num_shards = event.bot.shard_key
      return true unless num_shards

      (discord_id >> 22) % num_shards == shard_id
    end
  end
end
