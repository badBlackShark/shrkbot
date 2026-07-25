# frozen_string_literal: true

module TwilightStruggle
  class PostJob < ApplicationJob
    queue_as :default

    retry_on StandardError, wait: :polynomially_longer, attempts: 5
    discard_on ActiveJob::DeserializationError
    discard_on "Discordrb::Errors::UnknownChannel"
    discard_on "Discordrb::Errors::NoPermission"

    def perform(game, payload)
      Ops::TwilightStruggle::Games::Post.call(game:, report: GameReport.from_payload(payload))
    end
  end
end
