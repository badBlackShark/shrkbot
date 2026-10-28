# frozen_string_literal: true

module Feeds
  class VolumeLookup
    def self.call(watcher_class, external_id)
      Rails.cache.fetch(["feeds/volume", watcher_class.name, external_id], expires_in: 10.minutes) do
        watcher_class.volume(external_id)
      end
    rescue Integrations::Error
      nil
    end
  end
end
