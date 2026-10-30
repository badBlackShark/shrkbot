# frozen_string_literal: true

module Integrations
  module Twitch
    class Schedule
      def initialize(client: Client.new)
        @client = client
      end

      def segments(broadcaster_id, start_time: Time.current, first: 25)
        params = {broadcaster_id:, start_time: start_time.utc.iso8601, first:}
        @client.get_json("/schedule", params:) do |body|
          (body.fetch("data").fetch("segments") || []).map { |data| segment(data) }
        end
      rescue NotFound
        []
      end

      private

      def segment(data)
        category = data.fetch("category")
        Segment.new(
          id: data.fetch("id"),
          start_time: Time.zone.parse(data.fetch("start_time")),
          end_time: parse_time(data.fetch("end_time")),
          title: data.fetch("title"),
          category_id: category&.fetch("id"),
          category_name: category&.fetch("name"),
          canceled_until: parse_time(data.fetch("canceled_until")),
          recurring: data.fetch("is_recurring")
        )
      end

      def parse_time(value)
        Time.zone.parse(value) if value
      end
    end
  end
end
