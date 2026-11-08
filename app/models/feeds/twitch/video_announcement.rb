# frozen_string_literal: true

module Feeds
  module Twitch
    class VideoAnnouncement < MediaAnnouncement
      LINK_LABEL = "Watch on Twitch"
      LABELS = {
        "Integrations::Twitch::HighlightPublished" => "New highlight on Twitch",
        "Integrations::Twitch::UploadPublished" => "New upload on Twitch"
      }.freeze

      private

      def tokens
        {streamer: event.display_name, title: event.title}
      end

      def details
        Bot::Discord::Components.text(::Duration.about(event.duration).upcase_first)
      end
    end
  end
end
