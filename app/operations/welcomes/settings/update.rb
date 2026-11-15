# frozen_string_literal: true

module Ops
  module Welcomes
    module Settings
      class Update < ApplicationOperation
        include Ops::PluginConfiguration

        receives :server_configuration,
          :channel_id,
          :join_message,
          :leave_message,
          :ping_on_join,
          :suppress_removal_messages,
          :enabled

        def call
          settings = server_configuration.welcome_settings
          settings.assign_attributes(
            channel_id:,
            join_message:,
            leave_message:,
            ping_on_join:,
            suppress_removal_messages:
          )
          save_with_activation(settings)
        end

        private

        def plugin_key
          :welcomes
        end
      end
    end
  end
end
