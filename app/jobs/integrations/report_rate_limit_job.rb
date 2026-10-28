# frozen_string_literal: true

module Integrations
  class ReportRateLimitJob < ApplicationJob
    include NotifiesOwner

    queue_as :default

    def perform(label, message, retry_after)
      notify_owner(content(label, message, retry_after))
    end

    private

    def content(label, message, retry_after)
      wait = retry_after ? " Retry-After: #{retry_after} s." : ""
      "Polling was rate-limited at #{label}: #{message}. The batch stopped until the next tick.#{wait}"
    end
  end
end
