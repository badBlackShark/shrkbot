# frozen_string_literal: true

module Roles
  class MenuBackfill < BaseEvent
    on :ready

    def handle
      unposted_sets.find_each do |set|
        Ops::Roles::Messages::Post.call(bot: event.bot, role_set: set)
      end
    end

    private

    def unposted_sets
      Set.where(message_id: nil)
        .joins(role_setting: {server_configuration: {plugin_activations: :plugin}})
        .where(plugins: {key: "roles"})
        .where(plugin_activations: {enabled: true})
        .where(server_configurations: {discord_id: event.bot.servers.keys})
    end
  end
end
