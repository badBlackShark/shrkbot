# frozen_string_literal: true

class AddMessageToFeedPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :feed_posts, :channel_id, :bigint
    add_column :feed_posts, :message_id, :bigint
  end
end
