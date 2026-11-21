# frozen_string_literal: true

module Feeds
  class VolumeLookup
    FAILURE_TTL = 1.minute

    def self.call(watcher_class, external_id)
      key = ["feeds/volume/v1", watcher_class.name, external_id]
      Rails.cache.fetch(key, expires_in: 10.minutes) do
        watcher_class.volume(external_id)
      end
    rescue Integrations::Error
      Rails.cache.write(key, nil, expires_in: FAILURE_TTL)
      nil
    end
  end
end
