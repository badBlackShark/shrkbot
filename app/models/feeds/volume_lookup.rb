# frozen_string_literal: true

module Feeds
  class VolumeLookup
    def self.call(watcher_class, external_id)
      watcher_class.volume(external_id)
    rescue Integrations::Error
      nil
    end
  end
end
