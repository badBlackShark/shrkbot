# frozen_string_literal: true

module Integrations
  module Twitch
    class EventSubSubscriptions
      PATH = "/eventsub/subscriptions"

      def initialize(client: Client.new)
        @client = client
      end

      def all
        subscriptions = []
        cursor = nil
        loop do
          found, cursor = page(cursor)
          subscriptions.concat(found)
          break unless cursor
        end
        subscriptions
      end

      def create(type:, version:, condition:, callback:)
        @client.post_json(
          PATH,
          body: {type:, version:, condition:, transport: {method: "webhook", callback:, secret: ENV.fetch("TWITCH_EVENTSUB_SECRET")}}
        ) do |body|
          subscription(body.fetch("data").first)
        end
      end

      def destroy(id)
        @client.delete(PATH, params: {id:})
      end

      private

      def page(cursor)
        params = cursor ? {after: cursor} : {}
        @client.get_json(PATH, params:) do |body|
          [body.fetch("data").map { |data| subscription(data) }, body.fetch("pagination")["cursor"]]
        end
      end

      def subscription(data)
        EventSubSubscription.new(
          id: data.fetch("id"),
          type: data.fetch("type"),
          version: data.fetch("version"),
          status: data.fetch("status"),
          condition: data.fetch("condition"),
          callback: data.fetch("transport").fetch("callback")
        )
      end
    end
  end
end
