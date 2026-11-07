# frozen_string_literal: true

module Feeds
  module Twitch
    class VideoAnnouncement < MediaAnnouncement
      LINK_LABEL = "Watch on Twitch"
      LABELS = {
        "Integrations::Twitch::HighlightPublished" => "New highlight on Twitch",
        "Integrations::Twitch::UploadPublished" => "New upload on Twitch"
      }.freeze
      VERBS = {
        "Integrations::Twitch::HighlightPublished" => "posted a highlight",
        "Integrations::Twitch::UploadPublished" => "uploaded a video"
      }.freeze

      private

      def tokens
        {streamer: event.display_name, category: "", title: event.title}
      end

      def headline
        "#{event.display_name} #{VERBS.fetch(event.type)}: #{event.title}"
      end

      def details
        Bot::Discord::Components.text(::Duration.about(event.duration).upcase_first)
      end
    end
  end
end
