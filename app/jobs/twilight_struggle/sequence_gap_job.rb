# frozen_string_literal: true

module TwilightStruggle
  class SequenceGapJob < ApplicationJob
    MAX_REPORTED = 20

    queue_as :default

    retry_on StandardError, wait: :polynomially_longer, attempts: 5
    discard_on ActiveJob::DeserializationError
    discard_on "Discordrb::Errors::UnknownChannel"
    discard_on "Discordrb::Errors::NoPermission"

    def perform(external_id)
      ids = Finders::TwilightStruggle::MissingGameIds.new(external_id).ids
      return if ids.empty?

      deliver(message(ids))
    end

    private

    def deliver(content)
      Bot::Discord::Components.create_message(
        channel_id: Bot::Discord::Components.dm_channel_id(Bot::Config.owner_id),
        content:,
        allowed_mentions: {parse: []}
      )
    end

    def message(ids)
      return summary(ids) if ids.size > MAX_REPORTED

      "shrkbot never received Twilight Struggle #{"game".pluralize(ids.size)} #{ids.join(", ")}."
    end

    def summary(ids)
      "shrkbot never received #{ids.size} Twilight Struggle games, #{ids.first} to #{ids.last}."
    end
  end
end
