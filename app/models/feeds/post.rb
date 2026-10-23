# frozen_string_literal: true

module Feeds
  class Post < ApplicationRecord
    self.table_name = "feed_posts"

    belongs_to :subscription

    validates :story_key, presence: true, uniqueness: {scope: :subscription_id}
  end
end
