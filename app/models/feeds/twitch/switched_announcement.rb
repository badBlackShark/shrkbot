# frozen_string_literal: true

module Feeds
  module Twitch
    class SwitchedAnnouncement < Feeds::Announcement
      include ProfileHeader

      private

      def accent_color
        EndedAnnouncement::ACCENT_COLOR
      end

      def lead
        nil
      end

      def url
        "https://www.twitch.tv/#{event.login}"
      end

      def link_label
        Announcement::LINK_LABEL
      end

      def blocks
        header
      end

      def header_texts
        [eyebrow, heading, details]
      end

      def eyebrow
        Bot::Discord::Components.text("-# #{event.display_name} · Live on Twitch")
      end

      def details
        started = Bot::Discord::Timestamp.relative(Time.iso8601(event.started_at))
        Bot::Discord::Components.text([switched_line, "-# Started #{started}"].join("\n"))
      end

      def switched_line
        return "Switched away from the chosen categories" unless event.category_name

        "Switched to **#{event.category_name}**"
      end
    end
  end
end
