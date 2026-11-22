# frozen_string_literal: true

module Integrations
  module Twitch
    class ReportCategoryCheckBrokenJob < ApplicationJob
      include NotifiesOwner

      queue_as :default

      def perform(error)
        notify_owner(
          "Twitch category checks have failed for 24 hours: #{error}. Streams in followed categories " \
          "aren't announced until they recover. shrkbot retries every minute."
        )
      end
    end
  end
end
