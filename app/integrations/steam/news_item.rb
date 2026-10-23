# frozen_string_literal: true

module Integrations
  module Steam
    NewsItem = Data.define(
      :gid,
      :title,
      :url,
      :author,
      :contents,
      :feed_name,
      :feed_label,
      :feed_type,
      :published_at,
      :tags
    )
  end
end
