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
      return log_stale(game) if game.revision > revision

      report = GameReport.from_payload(payload)
      wait = PostSchedule.new(game:, server_configuration:, reported_at: report.reported_at).wait
      return self.class.set(wait:).perform_later(game, server_configuration, payload, revision) if wait.positive?

      Ops::TwilightStruggle::Games::Post.call(
        game:,
        server_configuration:,
        report:
      )
    end

    private

    def log_stale(game)
      Rails.logger.info { "#{self.class} dropped game #{game.external_id}: a newer version of it arrived." }
    end
  end
end
