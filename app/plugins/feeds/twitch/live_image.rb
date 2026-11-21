# frozen_string_literal: true

module Feeds
  class Twitch
    class LiveImage
      PREVIEW_TTL = 1.minute
      LAST_PREVIEW_TTL = 2.days

      def self.for(event, subscription:)
        return unless subscription.settings.show_preview_frame

        preview(event) || box_art(event)
      end

      def self.kept_for(event, subscription:)
        return unless subscription.settings.show_preview_frame

        Rails.cache.read(last_preview_key(event)) || box_art(event)
      end

      def self.preview(event)
        CachedFetch.call(["feeds/twitch/preview/v1", event.session], missing: "Twitch preview for #{event.login}", ttl: PREVIEW_TTL, failure_ttl: nil) do
          url = Integrations::Twitch::Previews.new.url_for(event.login)
          if url
            stamped = "#{url}?t=#{Time.current.to_i}"
            Rails.cache.write(last_preview_key(event), stamped, expires_in: LAST_PREVIEW_TTL)
            stamped
          end
        end
      end

      def self.box_art(event)
        GameLookup.find(event.category_id)&.box_art_url
      end

      def self.last_preview_key(event)
        ["feeds/twitch/preview/last/v1", event.session]
      end
      private_class_method :preview, :box_art, :last_preview_key
    end
  end
end
