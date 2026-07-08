# frozen_string_literal: true

module Ops
  module PluginConfiguration
    private

    def enabling?
      ActiveModel::Type::Boolean.new.cast(enabled)
    end

    def staged_activation
      activation = server_configuration.plugin_activations.find_or_initialize_by(plugin: Plugin.find_by!(key: plugin_key))
      activation.enabled = enabled
      activation
    end

    def plugin_key
      raise AbstractMethodError, "#{self.class} must implement #plugin_key"
    end

    def messages(*records)
      records.flat_map { |record| record.errors.full_messages }
    end
  end
end
