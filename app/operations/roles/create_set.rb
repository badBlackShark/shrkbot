module Ops
  module Roles
    class CreateSet < ApplicationOperation
      def initialize(server_configuration:, name:, selection_mode:, channel_override: nil)
        @server_configuration = server_configuration
        @name = name
        @selection_mode = selection_mode
        @channel_override = channel_override
      end

      def call
        set = transaction do
          setting = @server_configuration.role_setting || @server_configuration.create_role_setting!
          setting.role_sets.create!(
            name: @name,
            selection_mode: @selection_mode,
            channel_override: @channel_override,
            position: next_position(setting)
          )
        end
        ok(set)
      end

      private

      def next_position(setting)
        (setting.role_sets.maximum(:position) || -1) + 1
      end
    end
  end
end
