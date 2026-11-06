# frozen_string_literal: true

class AddLiveEndModeToFeedTwitchSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :feed_twitch_settings, :live_end_mode, :string, null: false, default: "mark_ended_with_vod"
    add_check_constraint :feed_twitch_settings,
      "live_end_mode IN ('keep', 'delete', 'mark_ended', 'mark_ended_with_vod')",
      name: "feed_twitch_settings_live_end_mode_check",
      validate: false
  end
end
