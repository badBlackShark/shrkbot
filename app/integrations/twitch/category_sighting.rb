# frozen_string_literal: true

module Integrations
  module Twitch
    class CategorySighting
      def initialize(streams:, watches:)
        @streams = streams
        @watches = watches
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

        !state["titles_pushed"] && Session.drifted?(state, live)
      end
    end
  end
end
