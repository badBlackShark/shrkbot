# frozen_string_literal: true

class AddStoryKeyIndexToFeedPosts < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :feed_posts, :story_key, algorithm: :concurrently
  end
end
