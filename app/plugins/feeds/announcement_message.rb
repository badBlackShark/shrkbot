# frozen_string_literal: true

module Feeds
  module AnnouncementMessage
    def self.create(channel_id:, announcement:, allowed_mentions: announcement.allowed_mentions)
      Bot::Discord::Components.create_with_subject(
        channel_id:,
        subject: announcement.subject,
        rendered: announcement.card,
        allowed_mentions:,
        fallback: announcement.fallback,
        attachments: announcement.attachments
      )
    end
  end
end
