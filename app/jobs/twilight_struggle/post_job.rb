# frozen_string_literal: true

module TwilightStruggle
  class PostJob < ApplicationJob
    queue_as :default
    limits_concurrency(
      to: 1,
      key: ->(game, server_configuration, *) { "#{game.id}-#{server_configuration.id}" }
    )
    self.log_arguments = false

    retry_on StandardError, wait: :polynomially_longer, attempts: 5
    discard_on ActiveJob::DeserializationError
    discard_on "Discordrb::Errors::UnknownChannel"
    discard_on "Discordrb::Errors::NoPermission"

    def perform(game, server_configuration, payload, revision = 0)
      return log_stale(game) if game.revision > revision

      report = GameReport.from_payload(payload)
      schedule = PostSchedule.new(game:, server_configuration:, reported_at: report.reported_at)
      wait = schedule.wait
      return self.class.set(wait:).perform_later(game, server_configuration, payload, revision) if wait.positive?

      Ops::TwilightStruggle::Games::Post.call(
        game:,
        server_configuration:,
        report:,
        config: schedule.config,
        posted_message: schedule.posted_message
      )
    end

    private

    def log_stale(game)
      Rails.logger.info { "#{self.class} dropped game #{game.external_id}: a newer version of it arrived." }
    end
  end
end
