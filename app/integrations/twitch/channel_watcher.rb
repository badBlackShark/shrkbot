# frozen_string_literal: true

module Integrations
  module Twitch
    class ChannelWatcher
      PREVIEW_URL = "https://static-cdn.jtvnw.net/previews-ttv/live_user_%<login>s-1280x720.jpg"

      def self.resolve(input, users: Users.new)
        target(users.find_by_login(ChannelReference.parse(input)))
      end

      def self.refresh(external_ids, users: Users.new)
        users.for(external_ids).map { |user| target(user) }
      end

      def self.followed_for_live
        Watch.demanding([StreamStarted.name]).where(watcher: name)
      end

      def self.preview_url(login)
        url = format(PREVIEW_URL, login:)
        # Until a stream's first frame exists, Twitch redirects this URL to its grey 404_preview image.
        Http.head(url, status_errors: {302 => NotFound})
        url
      rescue NotFound
        nil
      end

      def self.box_art_url(category_id, games: Games.new)
        games.find(category_id)&.box_art_url
      end

      def self.vod_url(user_id, stream_ids, videos: Videos.new)
        by_stream = videos.for_user(user_id, type: "archive", first: 20).index_by(&:stream_id)
        stream_ids.filter_map { |id| by_stream[id] }.first&.url
      end

      def self.target(user)
        Target.new(external_id: user.id, name: user.display_name, image_url: user.profile_image_url)
      end
      private_class_method :target
    end
  end
end
