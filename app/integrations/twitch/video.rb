# frozen_string_literal: true

module Integrations
  module Twitch
    Video = Data.define(
      :id,
      :stream_id,
      :user_id,
      :user_login,
      :user_name,
      :title,
      :description,
      :created_at,
      :published_at,
      :url,
      :thumbnail_url,
      :type,
      :duration
    ) do
      def processing?
        thumbnail_url.include?("/_404/404_processing")
      end
    end
  end
end
