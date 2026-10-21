# frozen_string_literal: true

module TwilightStruggle
  class PostJob < ApplicationJob
    queue_as :default
    self.log_arguments = false

    retry_on StandardError, wait: :polynomially_longer, attempts: 5
    discard_on ActiveJob::DeserializationError
    discard_on "Discordrb::Errors::UnknownChannel"
    discard_on "Discordrb::Errors::NoPermission"

    def perform(game, server_configuration, payload, revision)
      report = GameReport.from_payload(payload)
      wait = PostSchedule.new(game:, server_configuration:, reported_at: report.reported_at).wait
      return self.class.set(wait:).perform_later(game, server_configuration, payload, revision) if wait.positive?

      Ops::TwilightStruggle::Games::Post.call(
        game:,
        server_configuration:,
        report:,
        revision:
      )
    end
  end
end
