# frozen_string_literal: true

class AddRetractedAtToFeedPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :feed_posts, :retracted_at, :datetime
  end
end
