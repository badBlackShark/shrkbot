# frozen_string_literal: true

module Integrations
  module Twitch
    class Games
      BOX_ART_SIZE = "285x380"

      def initialize(client: Client.new)
        @client = client
      end

      def find(id)
        @client.get_json("/games", params: {id:}) do |body|
          data = body.fetch("data").first
          game(data) if data
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
