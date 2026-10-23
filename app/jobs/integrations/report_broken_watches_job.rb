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
      lines = watches.map { |watch| "#{watch.name} (#{watch.external_id}): #{watch.last_error}" }
      ["Polling has failed for 24 hours - shrkbot keeps retrying every hour:", *OwnerList.call(lines)].join("\n")
    end
  end
end
