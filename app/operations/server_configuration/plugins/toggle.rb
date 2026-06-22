module Ops
  module ServerConfiguration
    module Plugins
      class Toggle < ApplicationOperation
        receives :server_configuration, :plugin, :enabled

        def call
          activation = PluginActivation.find_or_initialize_by(server_configuration: server_configuration, plugin: plugin)
          activation.enabled = enabled
          if activation.enabled? && !prerequisites_met?
            return failure("#{plugin.name} can't be enabled until its required settings are configured.")
          end
          activation.save!
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
