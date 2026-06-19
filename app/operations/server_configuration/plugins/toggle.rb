module Ops
  module ServerConfiguration
    module Plugins
      class Toggle < ApplicationOperation
        receives :server_configuration, :plugin, :enabled

        def call
          if enabled && !prerequisites_met?
            return failure("#{plugin.name} can't be enabled until its required settings are configured.")
          end
          activation = PluginActivation.find_or_initialize_by(server_configuration: server_configuration, plugin: plugin)
          activation.update!(enabled: enabled)
          ok(activation)
        end

        private

        def prerequisites_met?
          definition = PluginCatalog.find(plugin.key)
          definition.nil? || definition.prerequisites_met?(server_configuration)
        end
      end
    end
  end
end
