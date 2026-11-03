# frozen_string_literal: true

module Feeds
  class Thumbnail
    FILENAME = "thumbnail.webp"

    def self.for(watch)
      url = artwork_url(watch)
      padded(watch, url) if url
    end

    def self.artwork_url(watch)
      CachedFetch.call(["feeds/artwork_url/v1", watch.watcher, watch.external_id], missing: missing(watch)) do
        watch.watcher_class.artwork_url(watch.external_id)
      end
    end

    def self.padded(watch, url)
      CachedFetch.call(["feeds/thumbnail/v1", url], missing: missing(watch), errors: [Integrations::Error, Vips::Error]) do
        SquareImage.call(watch.watcher_class.artwork(url))
      end
    end

    def self.missing(watch)
      "thumbnail for #{watch.watcher} #{watch.external_id}"
    end
    private_class_method :artwork_url, :padded, :missing
  end
end
