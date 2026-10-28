# frozen_string_literal: true

module Feeds
  class Thumbnail
    FILENAME = "thumbnail.webp"
    TTL = 1.day
    FAILURE_TTL = 10.minutes

    def self.for(watch)
      url = artwork_url(watch)
      padded(watch, url) if url
    end

    def self.artwork_url(watch)
      key = ["feeds/artwork_url/v1", watch.watcher, watch.external_id]
      Rails.cache.fetch(key, expires_in: TTL) { watch.watcher_class.artwork_url(watch.external_id) }
    rescue Integrations::Error => error
      failed(watch, key, error)
    end

    def self.padded(watch, url)
      key = ["feeds/thumbnail/v1", url]
      Rails.cache.fetch(key, expires_in: TTL) { SquareImage.call(watch.watcher_class.artwork(url)) }
    rescue Integrations::Error, Vips::Error => error
      failed(watch, key, error)
    end

    def self.failed(watch, key, error)
      Rails.logger.warn("Feeds: no thumbnail for #{watch.watcher} #{watch.external_id}: #{error.class}: #{error.message}")
      Rails.cache.write(key, nil, expires_in: FAILURE_TTL)
      nil
    end
    private_class_method :artwork_url, :padded, :failed
  end
end
