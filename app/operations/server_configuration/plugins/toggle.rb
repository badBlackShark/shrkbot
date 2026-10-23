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
          resume_feeds if activation.saved_change_to_enabled?(to: true)
          publish_roles_menu(activation) if plugin.key == :roles
        end

        def resume_feeds
          ::Ops::Feeds::SubscribedEvents::Resume.call(server_configuration:, plugin_key: plugin.key)
        end

        def publish_roles_menu(activation)
          ::Roles::MenuToggle.publish(server_configuration, enabled: activation.enabled?)
        end
      end
    end
  end
end
