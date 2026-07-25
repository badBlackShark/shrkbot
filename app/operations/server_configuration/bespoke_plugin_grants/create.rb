# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module BespokePluginGrants
      class Create < ApplicationOperation
        receives :server_configuration, :plugin_key

        def call
          grant = ::BespokePluginGrant.find_or_create_by!(server_configuration:, plugin_key:)
          Bot::ConfigBus.sync_commands(server_configuration)
          ok(grant)
        end
      end
    end
  end
end
