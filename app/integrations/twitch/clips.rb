# frozen_string_literal: true

module Integrations
  module Twitch
    class Clips
      PAGE_SIZE = 100

      def initialize(client: Client.new)
        @client = client
      end

      def for_broadcaster(broadcaster_id, started_at:, ended_at: Time.current, featured: nil)
        params = {
          broadcaster_id:,
          started_at: started_at.utc.iso8601,
          ended_at: ended_at.utc.iso8601,
          first: PAGE_SIZE
        }
        params[:is_featured] = featured unless featured.nil?
        @client.get_all("/clips", params:) do |body|
          body.fetch("data").map { |data| clip(data) }
        end
      end

      private

      def clip(data)
        Clip.new(
          id: data.fetch("id"),
          url: data.fetch("url"),
          broadcaster_id: data.fetch("broadcaster_id"),
          creator_name: data.fetch("creator_name"),
          video_id: data.fetch("video_id").presence,
          category_id: data.fetch("game_id").presence,
          title: data.fetch("title"),
          view_count: data.fetch("view_count"),
          created_at: Time.zone.parse(data.fetch("created_at")),
          thumbnail_url: data.fetch("thumbnail_url"),
          duration: data.fetch("duration"),
          featured: data.fetch("is_featured")
        )
      end
    end
  end
end
