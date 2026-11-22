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
          [watch, Live.from_stream(stream)] if watch && transition?(watch.state, stream)
        end
      end

      private

      def transition?(state, stream)
        return true unless state.key?("session")
        return true unless state.fetch("stream_ids").include?(stream.id)

        !state["titles_pushed"] && drifted?(state, stream)
      end

      def drifted?(state, stream)
        state["title"] != stream.title ||
          state["category_id"] != stream.category_id ||
          (state.key?("language") && state["language"] != stream.language)
      end
    end
  end
end
