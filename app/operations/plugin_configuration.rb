# frozen_string_literal: true

module Ops
  module PluginConfiguration
    private

    def save_with_activation(settings)
      return failure(settings.errors.full_messages) unless settings.valid?

      transaction do
        toggled = toggle_plugin
        if toggled.success?
          settings.save!
          yield if block_given?
        end
        toggled
      end
    end

    def toggle_plugin
      Ops::ServerConfiguration::Plugins::Toggle.call(
        server_configuration:,
        plugin: Plugin.find_by!(key: plugin_key),
        enabled:
      )
    end

    def plugin_key
      raise AbstractMethodError, "#{self.class} must implement #plugin_key"
    end
  end
end
