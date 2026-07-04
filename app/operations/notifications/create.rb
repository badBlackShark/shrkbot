# frozen_string_literal: true

module Ops
  module Notifications
    class Create < ApplicationOperation
      receives :server_configuration, :kind
      receives :data, default: {}

      def call
        ok(server_configuration.notifications.create!(kind:, data:))
      end
    end
  end
end
