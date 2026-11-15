# frozen_string_literal: true

module Feeds
  class Twitch
    class LiveImage
      PREVIEW_TTL = 1.minute

      def self.for(event)
        preview(event) || box_art(event)
      end

      def self.preview(event)
        Rails.cache.fetch(["feeds/twitch/preview/v1", event.session], expires_in: PREVIEW_TTL) do
          url = Integrations::Twitch::Previews.new.url_for(event.login)
          "#{url}?t=#{Time.current.to_i}" if url
        end
      rescue Integrations::Error => error
        Rails.logger.warn("Feeds: no Twitch preview for #{event.login}: #{error.class}: #{error.message}")
        nil
      end

      def self.box_art(event)
        GameLookup.find(event.category_id)&.box_art_url
      end
      private_class_method :preview, :box_art
    end
  end
end
