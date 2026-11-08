# frozen_string_literal: true

module Feeds
  module Steam
    class PreviewSamples < Feeds::PreviewSamples
      def card
        {
          eyebrow: Announcement.eyebrow(@watch_name, @event_type, value(:feed)),
          title: value(:title),
          body: value(:body),
          button: Announcement::LINK_LABEL
        }
      end

      private

      def watch_token
        "game"
      end
    end
  end
end
