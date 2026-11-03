# frozen_string_literal: true

module Feeds
  module Steam
    class Announcement < Feeds::Announcement
      TEXT_LIMIT = 4000
      LINK_LABEL = "Read the full post"
      TYPE_LABELS = {
        "Integrations::Steam::PatchNotesPublished" => "Patch notes",
        "Integrations::Steam::AnnouncementPublished" => "Announcement"
      }.freeze

      def self.eyebrow(game, event_type, feed_label)
        "#{game} · #{TYPE_LABELS.fetch(event_type, feed_label)}"
      end

      def initialize(event:, subscription:, thumbnail: nil)
        super(event:, subscription:)
        @thumbnail = thumbnail
      end

      def attachments
        [Bot::Discord::FileUpload.new(thumbnail, Thumbnail::FILENAME)] if thumbnail
      end

      private

      attr_reader :thumbnail

      def url
        event.url
      end

      def link_label
        LINK_LABEL
      end

      def tokens
        {
          game: event.watch.name,
          author: event.author,
          feed: event.feed_label
        }
      end

      def eyebrow_plain
        @eyebrow_plain ||= self.class.eyebrow(event.watch.name, event.type, event.feed_label)
      end

      def headline
        "#{eyebrow_plain}: #{event.title}"
      end

      def blocks
        [*header, excerpt, image].compact
      end

      def header
        texts = [eyebrow, heading]
        return texts unless thumbnail

        [Bot::Discord::Components.section(texts, accessory: Bot::Discord::Components.thumbnail("attachment://#{Thumbnail::FILENAME}"))]
      end

      def eyebrow_markdown
        "-# #{eyebrow_plain}"
      end

      def eyebrow
        Bot::Discord::Components.text(eyebrow_markdown)
      end

      def excerpt
        budget = TEXT_LIMIT - lead.to_s.length - eyebrow_markdown.length - heading_text.length
        body = Excerpt.new(event.body, subscription.settings.body_length, max: budget).to_s
        Bot::Discord::Components.text(body) if body.present?
      end

      def image
        image_url = Array(event.image_urls).first
        Bot::Discord::Components.media_gallery([image_url]) if image_url
      end
    end
  end
end
