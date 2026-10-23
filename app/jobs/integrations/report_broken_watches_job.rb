# frozen_string_literal: true

module Integrations
  class ReportBrokenWatchesJob < ApplicationJob
    include NotifiesOwner

    MAX_REPORTED = 10

    queue_as :default

    def perform
      watches = Watch.broken.where(broken_reported_at: nil).order(:failing_since).to_a
      return if watches.empty?

      notify_owner(message(watches))
      Ops::Integrations::Watches::MarkBrokenReported.call(watches:)
    end

    private

    def message(watches)
      lines = watches.first(MAX_REPORTED).map { |watch| "- #{watch.name} (#{watch.external_id}): #{watch.last_error}" }
      lines << "- and #{watches.size - MAX_REPORTED} more" if watches.size > MAX_REPORTED
      ["Polling has failed for 24 hours - shrkbot keeps retrying every hour:", *lines].join("\n")
    end
  end
end
