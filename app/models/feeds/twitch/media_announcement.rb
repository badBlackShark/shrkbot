# frozen_string_literal: true

module Feeds
  module Twitch
    class MediaAnnouncement < Feeds::Announcement
      include ProfileHeader

      private

      def accent_color
        Announcement::ACCENT_COLOR
      end

      def url
        event.url
      end

      def link_label
        self.class::LINK_LABEL
      end

      def blocks
        [*header, image]
      end

      def header_texts
        [eyebrow, heading, details]
      end

      def eyebrow
        Bot::Discord::Components.text("-# #{event.display_name} · #{self.class::LABELS.fetch(event.type)}")
      end

      def image
        Bot::Discord::Components.media_gallery([event.thumbnail_url])
      end
    end
  end
end
