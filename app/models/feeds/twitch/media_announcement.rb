# frozen_string_literal: true

module Feeds
  class Twitch
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
        [*header, image].compact
      end

      def header_texts
        [eyebrow, heading, details]
      end

      def image
        return unless subscription.settings.show_image?(post_type)

        Bot::Discord::Components.media_gallery([event.thumbnail_url])
      end
    end
  end
end
