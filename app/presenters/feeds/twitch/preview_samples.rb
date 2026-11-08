# frozen_string_literal: true

module Feeds
  module Twitch
    class PreviewSamples < Feeds::PreviewSamples
      STARTED = "Started 2 hours ago"
      ENDED = "Ended 5 minutes ago"
      STREAM_LENGTH_SECONDS = 7200
      VIDEO_LENGTH_SECONDS = 5400
      VIEWERS_SHOWN = "hidden group-has-[[data-viewers-toggle]:checked]/type:block"
      VIEWERS_HIDDEN = "group-has-[[data-viewers-toggle]:checked]/type:hidden"
      VIEWERS_WATCHING = 1234
      VIEWERS_PEAK = 2345
      CLIP_LINE = "30 s · made 5 minutes ago"

      def card
        return live_card if @event_type == ::Integrations::Twitch::StreamStarted.name
        return clip_card if ClipAnnouncement::LABELS.key?(@event_type)

        video_card
      end

      def end_mode_card(mode)
        case mode
        when "mark_ended_with_vod" then ended_card(vod: true)
        when "mark_ended" then ended_card(vod: false)
        when "keep" then live_card_ended
        end
      end

      private

      def watch_token
        "streamer"
      end

      def live_card_ended
        live_card.merge(body: live_card[:body] + [{text: "Stream ended 5 minutes ago", class: nil}])
      end

      def ended_card(vod:)
        {
          eyebrow: "#{@watch_name} · Was live on Twitch",
          title: value(:title),
          body: [
            {text: "Streamed #{value(:category)} for #{::Duration.about(STREAM_LENGTH_SECONDS)}", class: nil},
            {text: "At least #{VIEWERS_PEAK.to_fs(:delimited)} viewers at the peak · #{ENDED.downcase}", class: VIEWERS_SHOWN},
            {text: ENDED, class: VIEWERS_HIDDEN}
          ],
          button: (EndedAnnouncement::VOD_LABEL if vod)
        }
      end

      def live_card
        {
          eyebrow: "#{@watch_name} · Live on Twitch",
          title: value(:title),
          body: [
            {text: "Streaming #{value(:category)}", class: nil},
            {text: "#{VIEWERS_WATCHING.to_fs(:delimited)} watching · #{STARTED.downcase}", class: VIEWERS_SHOWN},
            {text: STARTED, class: VIEWERS_HIDDEN}
          ],
          button: Announcement::LINK_LABEL
        }
      end

      def clip_card
        {
          eyebrow: "#{@watch_name} · #{ClipAnnouncement::LABELS.fetch(@event_type)}",
          title: value(:title),
          body: "Clipped by #{value(:clipper)} from #{value(:category)}\n#{CLIP_LINE}",
          button: ClipAnnouncement::LINK_LABEL
        }
      end

      def video_card
        {
          eyebrow: "#{@watch_name} · #{VideoAnnouncement::LABELS.fetch(@event_type)}",
          title: value(:title),
          body: ::Duration.about(VIDEO_LENGTH_SECONDS).upcase_first,
          button: VideoAnnouncement::LINK_LABEL
        }
      end
    end
  end
end
