# frozen_string_literal: true

module Ops
  module Notifications
    class Dismiss < ApplicationOperation
      receives :notification

      def call
        notification.update!(dismissed_at: Time.current)
        ok(notification)
      end
    end
  end
end
