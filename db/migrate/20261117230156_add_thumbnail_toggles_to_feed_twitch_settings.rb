# frozen_string_literal: true

class AddThumbnailTogglesToFeedTwitchSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :feed_twitch_settings, :show_highlights_thumbnail, :boolean, null: false, default: true
    add_column :feed_twitch_settings, :show_uploads_thumbnail, :boolean, null: false, default: true
    add_column :feed_twitch_settings, :show_featured_clips_thumbnail, :boolean, null: false, default: true
    add_column :feed_twitch_settings, :show_clips_thumbnail, :boolean, null: false, default: true
  end
end
