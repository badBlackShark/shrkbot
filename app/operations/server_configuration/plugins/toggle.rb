# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module Plugins
      class Toggle < ApplicationOperation
        self.transactional = false

        receives :server_configuration, :plugin, :enabled
        receives :publish_menu, default: true

        def call
          activation = find_or_build_activation
          activation.enabled = enabled
          refusal = enabling_refusal(activation) || dependent_refusal(activation)
          return refuse(activation, refusal) if refusal

          activation.save!
          publish_side_effects(activation) if activation.saved_change_to_enabled?
          ok(activation)
        end

        private

        def find_or_build_activation
          server_configuration.plugin_activations.find_by(plugin:) || PluginActivation.new(server_configuration:, plugin:)
        end

        def enabling_refusal(activation)
          return unless activation.enabled?

          requirement_message if definition.blockers(server_configuration).any?
        end

        def requirement_message
          I18n.t(
            "operations.server_configuration.plugins.requires.#{plugin.key}",
            plugin: plugin.name,
            default: I18n.t("operations.server_configuration.plugins.requires_settings", plugin: plugin.name)
          )
        end

        def dependent_refusal(activation)
          dependent = PluginCatalog.unmet_dependent(plugin.key, server_configuration, enabled_keys: prospective_keys(activation))
          I18n.t("operations.server_configuration.plugins.still_needed", dependent: dependent.name) if dependent
        end

        def prospective_keys(activation)
          keys = server_configuration.enabled_plugin_keys
          activation.enabled? ? keys | [plugin.key] : keys - [plugin.key]
        end

        def refuse(activation, message)
          activation.restore_attributes
          failure(message, value: activation)
        end

        def definition
          PluginCatalog.find(plugin.key)
        end

        def publish_side_effects(activation)
          resume_feeds if activation.enabled?
          ActiveRecord.after_all_transactions_commit do
            Bot::ConfigBus.sync_commands(server_configuration)
            publish_roles_menu(activation) if publish_menu && plugin.key == :roles
          end
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
