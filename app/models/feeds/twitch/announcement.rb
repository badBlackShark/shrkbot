# frozen_string_literal: true

module Feeds
  module Twitch
    class Announcement < Feeds::Announcement
      LINK_LABEL = "Watch on Twitch"
      ACCENT_COLOR = 0x9146ff

      def initialize(event:, subscription:, image_url: nil)
        super(event:, subscription:)
        @image_url = image_url
      end

      private

      attr_reader :image_url

      def accent_color
        ACCENT_COLOR
      end

      def post_type
        "Integrations::Twitch::StreamStarted"
      end

      def url
        "https://www.twitch.tv/#{event.login}"
      end

      def link_label
        LINK_LABEL
      end

      def tokens
        {streamer: event.display_name, category: event.category_name}
      end

      def headline
        "#{event.display_name} is live: #{event.title}"
      end

      def blocks
        [*header, image].compact
      end

      def header
        texts = [eyebrow, heading, details]
        profile = event.watch.image_url
        return texts unless profile

        [Bot::Discord::Components.section(texts, accessory: Bot::Discord::Components.thumbnail(profile))]
      end

      def eyebrow
        Bot::Discord::Components.text("-# #{event.display_name} · Live on Twitch")
      end

      def details
        Bot::Discord::Components.text([category_line, "-# #{stats}"].compact.join("\n"))
      end

      def category_line
        "Streaming **#{event.category_name}**" if event.category_name
      end

      def stats
        started = "<t:#{Time.iso8601(event.started_at).to_i}:R>"
        return "Started #{started}" unless subscription.settings.show_viewers && event.viewer_count

        "#{event.viewer_count.to_fs(:delimited)} watching · started #{started}"
      end

      def image
        Bot::Discord::Components.media_gallery([image_url]) if image_url
      end
    end
  end
end
