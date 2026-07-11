# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module Plugins
      class Toggle < ApplicationOperation
        self.transactional = false

        receives :server_configuration, :plugin, :enabled

        def call
          activation = PluginActivation.find_or_initialize_by(server_configuration:, plugin:)
          activation.enabled = enabled
          if activation.enabled? && !prerequisites_met?
            return failure(I18n.t("operations.server_configuration.plugins.requires_settings", plugin: plugin.name))
          end
          activation.save!
          publish_side_effects(activation)
          ok(activation)
        end

        private

        def prerequisites_met?
          definition = PluginCatalog.find(plugin.key)
          definition.nil? || definition.prerequisites_met?(server_configuration)
        end

        def publish_side_effects(activation)
          Bot::ConfigBus.sync_commands(server_configuration)
          return unless plugin.key == :roles

          ::Roles::MenuToggle.publish(server_configuration, enabled: activation.enabled?)
        end
      end
    end
  end
end
