# frozen_string_literal: true

module Ops
  module ServerConfiguration
    module Plugins
      class Toggle < ApplicationOperation
        receives :server_configuration, :plugin, :enabled
        receives :publish_menu, default: true

        def call
          Lock.call(server_configuration:)
          activation = find_or_build_activation
          activation.enabled = enabled
          refusal = enabling_refusal(activation) || dependent_refusal(activation)
          return refuse(activation, refusal) if refusal

          activation.save!
          publish_side_effects(activation) if activation.saved_change_to_enabled?
          ok(activation)
        end

        def self.dependent_refusal(key, server_configuration, enabled_keys: server_configuration.enabled_plugin_keys)
          broken = PluginCatalog.dependents_broken_by(key, server_configuration, enabled_keys:)
          return if broken.empty?

          I18n.t(
            "operations.server_configuration.plugins.still_needed.#{key}",
            count: broken.size,
            dependents: broken.map(&:name).to_sentence
          )
        end

        private

        def find_or_build_activation
          server_configuration.plugin_activations.find_by(plugin:) || PluginActivation.new(server_configuration:, plugin:)
        end

        def enabling_refusal(activation)
          return unless activation.enabled? && activation.enabled_changed?

          blocker = definition.blockers(server_configuration).first
          requirement_message(blocker) if blocker
        end

        def requirement_message(blocker)
          case blocker
          when :channel_missing
            plugins_t("requires_channel")
          else
            plugins_t("requires.#{plugin.key}", default: plugins_t("requires_settings"))
          end
        end

        def dependent_refusal(activation)
          self.class.dependent_refusal(plugin.key, server_configuration, enabled_keys: prospective_keys(activation))
        end

        def plugins_t(key, **options)
          I18n.t("operations.server_configuration.plugins.#{key}", plugin: plugin.name, **options)
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
