# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module BespokePluginGrants
      class Destroy < ApplicationOperation
        receives :bespoke_plugin_grant

        def call
          config = bespoke_plugin_grant.server_configuration
          bespoke_plugin_grant.destroy!
          disable_plugin(config)
          ok(bespoke_plugin_grant)
        end

        private

        def disable_plugin(config)
          plugin = ::Plugin.find_by(key: bespoke_plugin_grant.plugin_key)
          if plugin
            Plugins::Toggle.call(server_configuration: config, plugin:, enabled: false)
          else
            Bot::ConfigBus.sync_commands(config)
          end
        end
      end
    end
  end
end
