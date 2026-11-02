# frozen_string_literal: true

module Integrations
  module Twitch
    class ReportUnauthorizedJob < ApplicationJob
      include NotifiesOwner

      queue_as :default

      def perform(message)
        notify_owner(
          "Twitch rejected shrkbot's app credentials: #{message}. Go-live posts stop " \
          "until TWITCH_CLIENT_ID and TWITCH_CLIENT_SECRET work again."
        )
      end
    end
  end
end
