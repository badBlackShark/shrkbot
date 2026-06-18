module Ops
  module ServerConfiguration
    class TogglePlugin < ApplicationOperation
      def initialize(server_configuration:, plugin:, enabled:)
        @server_configuration = server_configuration
        @plugin = plugin
        @enabled = enabled
      end

      def call
        if @enabled && !prerequisites_met?
          return failure("#{@plugin.name} can't be enabled until its required settings are configured.")
        end

        activation = PluginActivation.find_or_initialize_by(
          server_configuration: @server_configuration, plugin: @plugin
        )
        transaction do
          activation.update!(enabled: @enabled)
        end
        ok(activation)
      end

      private

      def prerequisites_met?
        definition = PluginCatalog.find(@plugin.key)
        definition.nil? || definition.prerequisites_met?(@server_configuration)
      end
    end
  end
end
