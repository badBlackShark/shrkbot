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

      owner_id = Bot::Config.owner_id
      return if owner_id.to_s.strip.empty?

      deliver(owner_id, message(ids))
    end

    private

    def deliver(owner_id, content)
      Bot::Discord::Components.create_message(channel_id: dm_channel_id(owner_id), content:, allowed_mentions: {parse: []})
    end

    def dm_channel_id(owner_id)
      response_id(Discordrb::API::User.create_pm(Bot::Config.rest_token, owner_id))
    end

    def response_id(response)
      JSON.parse(response)["id"]
    end

    def message(ids)
      "shrkbot never received #{missing(ids)}. #{instruction(ids)}"
    end

    def missing(ids)
      return "#{ids.size} Twilight Struggle games, #{ids.first} to #{ids.last}" if ids.size > MAX_REPORTED

      "Twilight Struggle #{"game".pluralize(ids.size)} #{ids.join(", ")}"
    end

    def instruction(ids)
      return "Re-post it from the site." if ids.one?

      "Re-post them from the site."
    end
  end
end
