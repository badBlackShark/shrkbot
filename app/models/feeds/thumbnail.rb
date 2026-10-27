# frozen_string_literal: true

module Feeds
  class Thumbnail
    FILENAME = "thumbnail.webp"
    TTL = 1.day
    FAILURE_TTL = 10.minutes

    def self.for(watch)
      url_key = ["feeds/artwork_url/v1", watch.watcher, watch.external_id]
      url = Rails.cache.fetch(url_key, expires_in: TTL) { watch.watcher_class.artwork_url(watch.external_id) }
      return unless url

      Rails.cache.fetch(["feeds/thumbnail/v1", url], expires_in: TTL) do
        SquareImage.call(Integrations::Http.get_bytes(url))
      end
    rescue Integrations::Error, Vips::Error => error
      Rails.logger.warn("Feeds: no thumbnail for #{watch.watcher} #{watch.external_id}: #{error.class}: #{error.message}")
      Rails.cache.write(url_key, nil, expires_in: FAILURE_TTL)
      nil
    end
  end
end
