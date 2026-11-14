# frozen_string_literal: true

module Feeds
  class Twitch
    module Ending
      def self.announcement(event:, subscription:)
        case subscription.settings.live_end_mode
        when "keep"
          kept(event, subscription)
        when "mark_ended"
          EndedAnnouncement.new(event:, subscription:, history: TitleHistory.for(event))
        else
          EndedAnnouncement.new(event:, subscription:, history: TitleHistory.for(event), vod_url: Vod.url_for(event))
        end
      end

      def self.kept(event, subscription)
        live = last_live(event)
        return SwitchedAnnouncement.new(event: live, subscription:, ended_at: event.ended_at) unless Twitch.accepts?(subscription, live)

        Announcement.new(event: live, subscription:, image_url: LiveImage.for(live), ended_at: event.ended_at)
      end

      def self.last_live(event)
        Integrations::Event
          .in_story(event.watch_id, event.story_key)
          .where.not(type: Integrations::Twitch::StreamEnded.name)
          .order(occurred_at: :desc, created_at: :desc, id: :desc)
          .first
      end
      private_class_method :kept, :last_live
    end
  end
end
