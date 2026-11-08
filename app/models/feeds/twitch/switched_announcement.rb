# frozen_string_literal: true

module Feeds
  module Twitch
    class SwitchedAnnouncement < Announcement
      private

      def accent_color
        EndedAnnouncement::ACCENT_COLOR
      end

      def lead
        nil
      end

      def blocks
        [*header, footer].compact
      end

      def details
        Bot::Discord::Components.text([switched_line, "-# Started #{started}"].join("\n"))
      end

      def switched_line
        return "Switched away from the chosen categories" unless event.category_name

        "Switched to **#{event.category_name}**"
      end
    end
  end
end
