# frozen_string_literal: true

module Integrations
  class ReportBrokenWatchesJob < ApplicationJob
    include NotifiesOwner

    queue_as :default

    def perform
      watches = Watch.broken.unreported.demanded.order(:failing_since).to_a
      return if watches.empty?

      notify_owner(message(watches))
      Ops::Integrations::Watches::MarkBrokenReported.call(watches:)
    end

    private

    def message(watches)
      lines = watches.map { |watch| "#{watch.label}: #{watch.last_error}" }
      ["Polling has failed for 24 hours - shrkbot keeps retrying every hour:", *owner_list(lines)].join("\n")
    end
  end
end
