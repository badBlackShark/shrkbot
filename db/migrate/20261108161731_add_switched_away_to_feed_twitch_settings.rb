# frozen_string_literal: true

class AddSwitchedAwayToFeedTwitchSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :feed_twitch_settings, :switched_away, :string, null: false, default: "summary"
    add_check_constraint :feed_twitch_settings,
      "switched_away IN ('summary', 'delete')",
      name: "feed_twitch_settings_switched_away_check",
      validate: false
  end
end
