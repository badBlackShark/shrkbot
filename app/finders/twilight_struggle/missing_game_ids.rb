# frozen_string_literal: true

module Finders
  module TwilightStruggle
    class MissingGameIds
      def initialize(arrived_external_id)
        @arrived_external_id = arrived_external_id
      end

      def ids
        return [] unless arrived_id
        return [] unless predecessor

        ((predecessor + 1)...arrived_id).to_a
      end

      private

      attr_reader :arrived_external_id

      def arrived_id
        return @arrived_id if defined?(@arrived_id)

        @arrived_id = Integer(arrived_external_id, exception: false)
      end

      def predecessor
        return @predecessor if defined?(@predecessor)

        @predecessor = earlier_games.maximum(Arel.sql("external_id::bigint"))
      end

      def earlier_games
        ::TwilightStruggle::Game
          .where("external_id ~ '^\\d+$'")
          .where("external_id::bigint < ?", arrived_id)
      end
    end
  end
end
