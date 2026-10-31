# frozen_string_literal: true

module Integrations
  module Twitch
    Video = Data.define(
      :id,
      :stream_id,
      :user_id,
      :title,
      :description,
      :created_at,
      :published_at,
      :url,
      :thumbnail_url,
      :type,
      :duration
    )
  end
end
