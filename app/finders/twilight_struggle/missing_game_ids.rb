# frozen_string_literal: true

module Finders
  module TwilightStruggle
    class MissingGameIds
      def initialize(arrived_external_id)
        @arrived_external_id = arrived_external_id
      end

      def ids
        return [] unless predecessor

        ((predecessor + 1)...arrived_id).to_a
      end

      private

      attr_reader :arrived_external_id

      def arrived_id
        @arrived_id ||= arrived_external_id.to_i
      end

      def predecessor
        return @predecessor if defined?(@predecessor)

        @predecessor = ::TwilightStruggle::Game
          .where("external_id::bigint < ?", arrived_id)
          .maximum(Arel.sql("external_id::bigint"))
      end
    end
  end
end
