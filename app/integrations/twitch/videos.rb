# frozen_string_literal: true

module Integrations
  module Twitch
    class Videos
      DURATION = /\A(?:(?<hours>\d+)h)?(?:(?<minutes>\d+)m)?(?:(?<seconds>\d+)s)?\z/

      def initialize(client: Client.new)
        @client = client
      end

      def for_user(user_id, type: "all", first: 20)
        @client.get_json("/videos", params: {user_id:, type:, first:}) do |body|
          body.fetch("data").map { |data| video(data) }
        end
      end

      private

      def video(data)
        Video.new(
          id: data.fetch("id"),
          stream_id: data.fetch("stream_id").presence,
          user_id: data.fetch("user_id"),
          title: data.fetch("title"),
          description: data.fetch("description"),
          created_at: Time.zone.parse(data.fetch("created_at")),
          published_at: Time.zone.parse(data.fetch("published_at")),
          url: data.fetch("url"),
          thumbnail_url: thumbnail(data.fetch("thumbnail_url")),
          type: data.fetch("type"),
          duration: seconds(data.fetch("duration"))
        )
      end

      # Twitch serves video thumbnails at 320x180 only.
      def thumbnail(template)
        template.sub("%{width}x%{height}", "320x180")
      end

      def seconds(duration)
        parts = DURATION.match(duration)
        raise Unavailable, "Twitch sent an unreadable video duration #{duration.inspect}" unless parts

        (parts[:hours].to_i * 3600) + (parts[:minutes].to_i * 60) + parts[:seconds].to_i
      end
    end
  end
end
