# frozen_string_literal: true

class AddShowPreviewFrameToFeedTwitchSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :feed_twitch_settings, :show_preview_frame, :boolean, null: false, default: true
  end
end
