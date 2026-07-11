# frozen_string_literal: true

module Roles
  class MenuReconcile < Bot::BaseEvent
    on :ready

    def handle
      unposted_sets.find_each do |set|
        Ops::Roles::Messages::Post.call(bot: event.bot, role_set: set)
      end
      lingering_sets.find_each do |set|
        Ops::Roles::Messages::Remove.call(bot: event.bot, role_set: set)
      end
    end

    private

    def unposted_sets
      shard_sets(enabled: true).where(message_id: nil)
    end

    def lingering_sets
      shard_sets(enabled: false).where.not(message_id: nil)
    end

    def shard_sets(enabled:)
      Set.includes(:role_setting)
        .joins(role_setting: {server_configuration: {plugin_activations: :plugin}})
        .where(plugins: {key: "roles"})
        .where(plugin_activations: {enabled:})
        .where(server_configurations: {discord_id: event.bot.servers.keys})
    end
  end
end
