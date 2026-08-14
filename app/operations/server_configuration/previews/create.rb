# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module Previews
      class Create < ApplicationOperation
        def call
          server_configuration = Ensure.call(discord_id: PreviewData.guild[:discord_id]).value
          server_configuration.update!(**guild_attributes)
          ServerChannels::Sync.call(server_configuration:, channels: PreviewData.channels)
          ServerRoles::Sync.call(
            server_configuration:,
            roles: PreviewData.roles,
            bot_role_position: PreviewData.guild[:bot_role_position]
          )
          apply_plugins(server_configuration)
          ok(server_configuration)
        end

        private

        def guild_attributes
          PreviewData.guild.slice(:name, :member_count, :icon_hash, :force_dm_reminders)
        end

        def apply_plugins(server_configuration)
          preload_plugin_activations(server_configuration)
          PreviewData.plugins.each do |entry|
            ApplyPlugin.call(server_configuration:, entry:)
          end
        end

        def preload_plugin_activations(server_configuration)
          activations = server_configuration.plugin_activations.includes(:plugin).to_a
          server_configuration.association(:plugin_activations).target = activations
        end
      end
    end
  end
end
