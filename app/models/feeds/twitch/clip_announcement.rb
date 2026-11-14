# frozen_string_literal: true

module Feeds
  class Twitch
    class ClipAnnouncement < MediaAnnouncement
      LINK_LABEL = "Watch the clip"

      def initialize(event:, subscription:, category: nil)
        super(event:, subscription:)
        @category = category
      end

      private

      attr_reader :category

      def tokens
        {streamer: event.display_name, category: category&.name.to_s, title: event.title, clipper: event.creator_name}
      end

      def details
        Bot::Discord::Components.text([clipped_by, "-# #{stats}"].join("\n"))
      end

      def clipped_by
        line = "Clipped by #{event.creator_name}"
        category ? "#{line} from **#{category.name}**" : line
      end

      def stats
        "#{event.duration.to_f.round} s · made #{Bot::Discord::Timestamp.relative(event.occurred_at)}"
      end
    end
  end
end
