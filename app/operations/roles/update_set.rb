module Ops
  module Roles
    class UpdateSet < ApplicationOperation
      def initialize(role_set:, name:, selection_mode:, channel_override:)
        @role_set = role_set
        @name = name
        @selection_mode = selection_mode
        @channel_override = channel_override
      end

      def call
        transaction do
          @role_set.update!(name: @name, selection_mode: @selection_mode, channel_override: @channel_override)
        end
        ok(@role_set)
      end
    end
  end
end
