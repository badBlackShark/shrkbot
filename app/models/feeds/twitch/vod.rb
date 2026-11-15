# frozen_string_literal: true

module Feeds
  class Twitch
    module Vod
      TTL = 1.day
      RECENT_ARCHIVES = 20

      def self.url_for(event)
        Rails.cache.fetch(["feeds/twitch/vod/v1", event.session], expires_in: TTL) do
          archive_url(event)
        end
      end

      def self.archive_url(event)
        archives = Integrations::Twitch::Videos.new.for_user(
          event.watch.external_id,
          type: "archive",
          first: RECENT_ARCHIVES
        )
        by_stream = archives.index_by(&:stream_id)
        event.stream_ids.filter_map { |id| by_stream[id] }.first&.url
      end
      private_class_method :archive_url
    end
  end
end
