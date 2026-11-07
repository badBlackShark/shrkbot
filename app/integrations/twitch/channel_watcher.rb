# frozen_string_literal: true

module Integrations
  module Twitch
    class ChannelWatcher
      VIDEO_EVENTS = {"highlight" => HighlightPublished, "upload" => UploadPublished}.freeze
      CLIP_OVERLAP = 10.minutes
      RECENT_VIDEOS = 20

      def self.resolve(input, users: Users.new)
        target(users.find_by_login(ChannelReference.parse(input)))
      end

      def self.refresh(external_ids, users: Users.new)
        users.for(external_ids).map { |user| target(user) }
      end

      def self.followed_for_live
        Watch.demanding([StreamStarted.name]).where(watcher: name)
      end

      def self.live_checked
        followed_for_live.or(Watch.where(watcher: name).where("state ? 'session'"))
      end

      def self.target(user)
        Target.new(external_id: user.id, name: user.display_name, image_url: user.profile_image_url)
      end
      private_class_method :target

      def initialize(watch, videos: Videos.new, clips: Clips.new)
        @watch = watch
        @videos = videos
        @clips = clips
      end

      def observe
        [
          *video_events,
          *clip_events(ClipCreated, clip_window_start, prefix: "clip"),
          *clip_events(FeaturedClipPublished, Event::FRESHNESS_WINDOW.ago, prefix: "featured-clip", featured: true)
        ]
      end

      private

      def wanted?(event_class)
        @watch.demanded_types.include?(event_class.name)
      end

      def video_events
        wanted = VIDEO_EVENTS.select { |_type, klass| wanted?(klass) }
        return [] if wanted.empty?

        @videos.for_user(@watch.external_id, type: "all", first: RECENT_VIDEOS).filter_map do |video|
          klass = wanted[video.type]
          next if klass.nil? || video.processing?

          klass.new(
            watch: @watch,
            subject_key: "video:#{video.id}",
            story_key: "video:#{video.id}",
            occurred_at: video.published_at,
            video_id: video.id,
            login: video.user_login,
            display_name: video.user_name,
            title: video.title,
            url: video.url,
            thumbnail_url: video.thumbnail_url,
            duration: video.duration
          )
        end
      end

      def clip_events(klass, started_at, prefix:, featured: nil)
        return [] unless wanted?(klass)

        @clips.for_broadcaster(@watch.external_id, started_at:, featured:).map do |clip|
          klass.new(
            watch: @watch,
            subject_key: "#{prefix}:#{clip.id}",
            story_key: "clip:#{clip.id}",
            occurred_at: clip.created_at,
            clip_id: clip.id,
            display_name: clip.broadcaster_name,
            title: clip.title,
            url: clip.url,
            thumbnail_url: clip.thumbnail_url,
            duration: clip.duration,
            creator_name: clip.creator_name,
            category_id: clip.category_id
          )
        end
      end

      def clip_window_start
        floor = Event::FRESHNESS_WINDOW.ago
        last_good = @watch.failing_since || @watch.polled_at
        return floor unless last_good

        [last_good - CLIP_OVERLAP, floor].max
      end
    end
  end
end
