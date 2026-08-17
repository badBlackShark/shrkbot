# frozen_string_literal: true

module Ops
  module Notification
    class Read < ApplicationOperation
      receives :notification

      def call
        notification.update!(read_at: Time.current) if notification.read_at.nil?
        ok(notification)
      end
    end
  end
end
