# frozen_string_literal: true

module Finders
  module TwilightStruggle
    class MissingGameIds
      def initialize(candidate_ids)
        @candidate_ids = candidate_ids
      end

      def ids
        (candidate_ids - stored_ids).sort
      end

      private

      attr_reader :candidate_ids

      def stored_ids
        ::TwilightStruggle::Game
          .where(external_id: candidate_ids.map(&:to_s))
          .pluck(:external_id)
          .map(&:to_i)
      end
    end
  end
end
