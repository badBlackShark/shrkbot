# frozen_string_literal: true

module Integrations
  module Twitch
    class Streams
      def initialize(client: Client.new)
        @client = client
      end

      def live(user_ids)
        user_ids.each_slice(Client::MAX_IDS).flat_map do |ids|
          @client.get_json("/streams", params: {user_id: ids, first: Client::MAX_IDS}) do |body|
            body.fetch("data").map { |data| stream(data) }
          end
        end
      end

      private

      def stream(data)
        Stream.new(
          id: data.fetch("id"),
          user_id: data.fetch("user_id"),
          user_login: data.fetch("user_login"),
          user_name: data.fetch("user_name"),
          category_id: data.fetch("game_id").presence,
          category_name: data.fetch("game_name").presence,
          title: data.fetch("title"),
          viewer_count: data.fetch("viewer_count"),
          started_at: Time.zone.parse(data.fetch("started_at")),
          thumbnail_url: data.fetch("thumbnail_url")
        )
      end
    end
  end
end
