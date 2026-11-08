# frozen_string_literal: true

module Integrations
  module Twitch
    class Categories
      RESULTS = 20

      def initialize(client: Client.new)
        @client = client
      end

      def search(query)
        @client.get_json("/search/categories", params: {query:, first: RESULTS}) do |body|
          body.fetch("data").map { |data| category(data) }
        end
      end

      private

      def category(data)
        Game.new(
          id: data.fetch("id"),
          name: data.fetch("name"),
          box_art_url: data.fetch("box_art_url")
        )
      end
    end
  end
end
