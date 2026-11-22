# frozen_string_literal: true

module Feeds
  class Twitch
    class EndedAnnouncement < Feeds::Announcement
      include ProfileHeader

      VOD_LABEL = "Watch the VOD"
      ACCENT_COLOR = 0x80848e

      def initialize(event:, subscription:, history:, vod_url: nil)
        super(event:, subscription:)
        @history = history
        @vod_url = vod_url
      end

      private

      attr_reader :history, :vod_url

      def accent_color
        ACCENT_COLOR
      end

      def lead
        nil
      end

      def url
        vod_url
      end

      def link_label
        VOD_LABEL
      end

      def buttons
        vod_url ? super : []
      end

      def blocks
        header
      end

      def header_texts
        [eyebrow, summary_heading, details]
      end

      def multi_title?
        history.size >= 2
      end

      def eyebrow
        Bot::Discord::Components.text("-# #{event.display_name} · Was live on Twitch")
      end

      def summary_heading
        return Bot::Discord::Components.text("## #{Bot::Discord::Truncate.call(single_title, TITLE_LIMIT)}") unless multi_title?

        Bot::Discord::Components.text("## Streamed for #{::Duration.about(event.duration)}")
      end

      def details
        body = multi_title? ? history_lines : summary_line
        Bot::Discord::Components.text("#{body}\n-# #{stats}")
      end

      def single_title
        history.first&.title || event.title
      end

      def single_category
        history.empty? ? event.category_name : history.first.category
      end

      def summary_line
        category = " **#{single_category}**" if single_category
        "Streamed#{category} for #{::Duration.about(event.duration)}"
      end

      def history_lines
        lines = history.first(TitleHistory::MAX_LINES).map { |entry| history_line(entry) }
        remaining = history.size - TitleHistory::MAX_LINES
        lines << "and #{remaining} more" if remaining.positive?
        lines.join("\n")
      end

      def history_line(entry)
        "- #{entry.title}#{category_part(entry)} · #{::Duration.about(entry.seconds)}"
      end

      def category_part(entry)
        return if entry.category.nil? || TitleMatch.names?(entry.title, entry.category)

        " · **#{entry.category}**"
      end

      def stats
        ended = Bot::Discord::Timestamp.relative(Time.iso8601(event.ended_at))
        return "Ended #{ended}" unless subscription.settings.show_viewers && event.peak_viewers

        "At least #{event.peak_viewers.to_fs(:delimited)} viewers at the peak · ended #{ended}"
      end
    end
  end
end
