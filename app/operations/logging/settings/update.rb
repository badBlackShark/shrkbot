# frozen_string_literal: true

module Ops
  module Logging
    module Settings
      class Update < ApplicationOperation
        include Ops::PluginConfiguration

        receives :server_configuration, :channel_id, :enabled_actions, :enabled

        def call
          settings = server_configuration.logging_settings
          settings.assign_attributes(channel_id:, enabled_actions:)
          save_with_activation(settings)
        end

        private

        def plugin_key
          :logging
        end
      end
    end
  end
end
