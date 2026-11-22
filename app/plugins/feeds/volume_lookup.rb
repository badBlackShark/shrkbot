# frozen_string_literal: true

module Feeds
  class VolumeLookup
    FAILURE_TTL = 1.minute

    def self.call(watcher_class, external_id)
      CachedFetch.call(
        ["feeds/volume/v1", watcher_class.name, external_id],
        missing: "volume for #{watcher_class.name} #{external_id}",
        ttl: 10.minutes,
        failure_ttl: FAILURE_TTL
      ) do
        watcher_class.volume(external_id)
      end
    end
  end
end
