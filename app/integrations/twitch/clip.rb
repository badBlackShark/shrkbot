# frozen_string_literal: true

module Integrations
  module Twitch
    Clip = Data.define(
      :id,
      :url,
      :broadcaster_id,
      :broadcaster_name,
      :creator_name,
      :video_id,
      :category_id,
      :title,
      :view_count,
      :created_at,
      :thumbnail_url,
      :duration,
      :featured
    )
  end
end
