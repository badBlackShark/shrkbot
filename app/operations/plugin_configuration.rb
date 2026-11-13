# frozen_string_literal: true

module Ops
  module PluginConfiguration
    private

    def save_with_activation(settings, publish_menu: true)
      return failure(settings.errors.full_messages) unless settings.valid?

      transaction do
        toggled = toggle_plugin(publish_menu:)
        if toggled.success?
          settings.save!
          yield if block_given?
        end
        toggled
      end
    end

    def toggle_plugin(publish_menu: true)
      Ops::ServerConfiguration::Plugins::Toggle.call(
        server_configuration:,
        plugin: Plugin.find_by!(key: plugin_key),
        enabled:,
        publish_menu:
      )
    end

    def plugin_key
      raise AbstractMethodError, "#{self.class} must implement #plugin_key"
    end
  end
end
