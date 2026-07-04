# frozen_string_literal: true

module Ops
  module Notifications
    class MarkRead < ApplicationOperation
      receives :server_configurations

      def call
        Notification.where(server_configuration: server_configurations).unread.update_all(read_at: Time.current)
        ok
      end
    end
  end
end
