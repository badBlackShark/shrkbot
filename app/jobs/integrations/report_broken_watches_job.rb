# frozen_string_literal: true

module Integrations
  class ReportBrokenWatchesJob < ApplicationJob
    MAX_REPORTED = 10

    queue_as :default

    retry_on StandardError, wait: :polynomially_longer, attempts: 5
    discard_on ActiveJob::DeserializationError
    discard_on "Discordrb::Errors::UnknownChannel"
    discard_on "Discordrb::Errors::NoPermission"

    def perform
      watches = Watch.broken.where(broken_reported_at: nil).order(:failing_since).to_a
      return if watches.empty?

      deliver(message(watches))
      Ops::Integrations::Watches::MarkBrokenReported.call(watches:)
    end

    private

    def deliver(content)
      Bot::Discord::Components.create_message(
        channel_id: Bot::Discord::Components.dm_channel_id(Bot::Config.owner_id),
        content: Bot::Discord::Truncate.call(content, 2000),
        allowed_mentions: {parse: []}
      )
    end

    def message(watches)
      lines = watches.first(MAX_REPORTED).map { |watch| "- #{watch.name} (#{watch.external_id}): #{watch.last_error}" }
      lines << "- and #{watches.size - MAX_REPORTED} more" if watches.size > MAX_REPORTED
      ["Polling has failed for 24 hours - shrkbot keeps retrying every hour:", *lines].join("\n")
    end
  end
end
