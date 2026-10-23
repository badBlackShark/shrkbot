# frozen_string_literal: true

module TwilightStruggle
  class SequenceGapJob < ApplicationJob
    include NotifiesOwner

    MAX_REPORTED = 20

    queue_as :default

    discard_on ActiveJob::DeserializationError

    def perform(candidate_ids)
      ids = Finders::TwilightStruggle::MissingGameIds.new(candidate_ids).ids
      return if ids.empty?

      notify_owner(message(ids))
    end

    private

    def message(ids)
      return summary(ids) if ids.size > MAX_REPORTED

      "shrkbot never received Twilight Struggle #{"game".pluralize(ids.size)} #{ids.join(", ")}."
    end

    def summary(ids)
      "shrkbot never received #{ids.size} Twilight Struggle games, #{ids.first} to #{ids.last}."
    end
  end
end
