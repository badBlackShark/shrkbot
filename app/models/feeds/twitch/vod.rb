# frozen_string_literal: true

module Feeds
  module Twitch
    class Vod
      TTL = 1.day

      def self.url_for(event)
        Rails.cache.fetch(["feeds/twitch/vod/v1", event.session], expires_in: TTL) do
          event.watch.watcher_class.vod_url(event.watch.external_id, event.stream_ids)
        end
      end
    end
  end
end
