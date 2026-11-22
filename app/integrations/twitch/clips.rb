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
          broadcaster_name: data.fetch("broadcaster_name"),
          creator_name: data.fetch("creator_name"),
          category_id: data.fetch("game_id").presence,
          title: data.fetch("title"),
          created_at: Time.zone.parse(data.fetch("created_at")),
          thumbnail_url: data.fetch("thumbnail_url"),
          duration: data.fetch("duration")
        )
      end
    end
  end
end
