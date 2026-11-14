# frozen_string_literal: true

module Feeds
  class Twitch
    class Announcement < Feeds::Announcement
      include ProfileHeader

      LINK_LABEL = "Watch on Twitch"
      ACCENT_COLOR = 0x9146ff

      def initialize(event:, subscription:, image_url: nil, ended_at: nil)
        super(event:, subscription:)
        @image_url = image_url
        @ended_at = ended_at
      end

      private

      attr_reader :image_url, :ended_at

      def accent_color
        ACCENT_COLOR
      end

      def url
        Integrations::Twitch::ChannelReference.url(event.login)
      end

      def link_label
        LINK_LABEL
      end

      def tokens
        {streamer: event.display_name, category: event.category_name, title: event.title}
      end

      def blocks
        [*header, image, footer].compact
      end

      def header_texts
        [eyebrow, heading, details]
      end

      def details
        Bot::Discord::Components.text([category_line, "-# #{stats}"].compact.join("\n"))
      end

      def category_line
        "Streaming **#{event.category_name}**" if event.category_name
      end

      def stats
        return "Started #{started}" unless subscription.settings.show_viewers && event.viewer_count

        "#{event.viewer_count.to_fs(:delimited)} watching · started #{started}"
      end

      def started
        Bot::Discord::Timestamp.relative(Time.iso8601(event.started_at))
      end

      def footer
        Bot::Discord::Components.text("-# Stream ended #{Bot::Discord::Timestamp.relative(Time.iso8601(ended_at))}") if ended_at
      end

      def image
        Bot::Discord::Components.media_gallery([image_url]) if image_url
      end
    end
  end
end
