# frozen_string_literal: true

module Integrations
  module Twitch
    Live = Data.define(:stream_id, :started_at, :title, :category_id, :category_name, :login, :display_name, :viewer_count) do
      def self.from_stream(stream)
        new(
          stream_id: stream.id,
          started_at: stream.started_at,
          title: stream.title,
          category_id: stream.category_id,
          category_name: stream.category_name,
          login: stream.user_login,
          display_name: stream.user_name,
          viewer_count: stream.viewer_count
        )
      end

      def self.from_online(event, channel)
        new(
          stream_id: event.fetch("id"),
          started_at: Time.iso8601(event.fetch("started_at")).in_time_zone,
          title: channel.title,
          category_id: channel.category_id,
          category_name: channel.category_name,
          login: event.fetch("broadcaster_user_login"),
          display_name: event.fetch("broadcaster_user_name"),
          viewer_count: 0
        )
      end
    end
  end
end
