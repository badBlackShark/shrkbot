# frozen_string_literal: true

module Feeds
  module Twitch
    class LiveImage
      def self.for(event)
        preview(event) || box_art(event)
      end

      def self.preview(event)
        url = event.watch.watcher_class.preview_url(event.login)
        "#{url}?t=#{Time.current.to_i}" if url
      rescue Integrations::Error => error
        Rails.logger.warn("Feeds: no Twitch preview for #{event.login}: #{error.class}: #{error.message}")
        nil
      end

      def self.box_art(event)
        return unless event.category_id

        CachedFetch.call(["feeds/twitch/box_art/v1", event.category_id], missing: "Twitch box art for category #{event.category_id}") do
          event.watch.watcher_class.box_art_url(event.category_id)
        end
      end
      private_class_method :preview, :box_art
    end
  end
end
