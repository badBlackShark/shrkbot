# frozen_string_literal: true

class AddMediaRolesToFeedTwitchSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :feed_twitch_settings, :highlights_role_id, :bigint
    add_column :feed_twitch_settings, :uploads_role_id, :bigint
    add_column :feed_twitch_settings, :featured_clips_role_id, :bigint
    add_column :feed_twitch_settings, :clips_role_id, :bigint
  end
end
