# frozen_string_literal: true

module Ops
  module TwilightStruggle
    class Configure < ApplicationOperation
      include Ops::PluginConfiguration

      receives :server_configuration, :enabled

      def call
        activation = staged_activation

        return failure(messages(activation), value: activation) unless activation.valid?

        save_activation!(activation)
        ok(activation)
      end

      private

      def plugin_key
        ::TwilightStruggle::PLUGIN_KEY
      end
    end
  end
end
