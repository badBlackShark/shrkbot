# frozen_string_literal: true

module Integrations
  module Twitch
    Stream = Data.define(
      :id,
      :user_id,
      :user_login,
      :user_name,
      :category_id,
      :category_name,
      :title,
      :viewer_count,
      :started_at,
      :thumbnail_url
    )
  end
end
