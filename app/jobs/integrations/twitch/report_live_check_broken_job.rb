# frozen_string_literal: true

module Integrations
  module Twitch
    class ReportLiveCheckBrokenJob < ApplicationJob
      include NotifiesOwner

      queue_as :default

      def perform(error)
        notify_owner(
          "Twitch live checks have failed for 24 hours: #{error}. Live cards stop updating " \
          "and stream ends wait for EventSub until Twitch answers again. shrkbot retries every 10 minutes."
        )
      end
    end
  end
end
