# frozen_string_literal: true

module Integrations
  module Twitch
    class CategoryStreams
      CACHE_TTL = 2.minutes

      def initialize(streams: Streams.new)
        @streams = streams
      end

      def refresh(category_id)
        found = @streams.in_category(category_id)
        Rails.cache.write(key(category_id), found, expires_in: CACHE_TTL)
        found
      end

      def current(category_id)
        Rails.cache.read(key(category_id)) || refresh(category_id)
      end

      private

      def key(category_id)
        "integrations/twitch/category_streams/#{category_id}"
      end
    end
  end
end
