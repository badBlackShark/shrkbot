# frozen_string_literal: true

module Integrations
  module Twitch
    class CategorySighting
      def initialize(streams:, watches:, floors: {})
        @streams = streams
        @watches = watches
        @floors = floors
      end

      def observations
        @streams.filter_map do |stream|
          watch = @watches[stream.user_id]
          next unless watch

          live = Live.from_stream(stream)
          [watch, live] if transition?(watch.state, live)
        end
      end

      private

      def transition?(state, live)
        return true unless state.key?("session")
        return true unless state.fetch("stream_ids").include?(live.stream_id)

        crossed_floor?(state, live) || (!state["titles_pushed"] && Session.drifted?(state, live))
      end

      def crossed_floor?(state, live)
        before = state["viewer_count"].to_i
        @floors.fetch(live.category_id, []).any? { |floor| before < floor && floor <= live.viewer_count }
      end
    end
  end
end
