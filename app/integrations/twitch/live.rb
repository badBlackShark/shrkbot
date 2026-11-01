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
    end
  end
end
