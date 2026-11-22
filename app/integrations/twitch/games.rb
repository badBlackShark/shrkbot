# frozen_string_literal: true

module Integrations
  module Twitch
    class Games
      BOX_ART_SIZE = "285x380"

      def initialize(client: Client.new)
        @client = client
      end

      def find(id)
        self.for([id]).first
      end

      def for(ids)
        ids.each_slice(Client::MAX_IDS).flat_map do |slice|
          @client.get_json("/games", params: {id: slice}) do |body|
            body.fetch("data").map { |data| game(data) }
          end
        end
      end

      private

      def game(data)
        Game.new(
          id: data.fetch("id"),
          name: data.fetch("name"),
          box_art_url: data.fetch("box_art_url").sub("{width}x{height}", BOX_ART_SIZE)
        )
      end
    end
  end
end
