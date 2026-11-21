# frozen_string_literal: true

module Integrations
  module Twitch
    Clip = Data.define(
      :id,
      :url,
      :broadcaster_name,
      :creator_name,
      :category_id,
      :title,
      :created_at,
      :thumbnail_url,
      :duration
    )
  end
end
