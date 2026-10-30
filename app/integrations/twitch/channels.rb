# frozen_string_literal: true

module Integrations
  module Twitch
    class Channels
      def initialize(client: Client.new)
        @client = client
      end

      def for(broadcaster_ids)
        broadcaster_ids.each_slice(Client::MAX_IDS).flat_map do |ids|
          @client.get_json("/channels", params: {broadcaster_id: ids}) do |body|
            body.fetch("data").map { |data| channel(data) }
          end
        end
      end

      private

      def channel(data)
        Channel.new(
          broadcaster_id: data.fetch("broadcaster_id"),
          title: data.fetch("title"),
          category_id: data.fetch("game_id").presence,
          category_name: data.fetch("game_name").presence
        )
      end
    end
  end
end
