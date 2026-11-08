# frozen_string_literal: true

class ValidateFeedTwitchSettingsSwitchedAway < ActiveRecord::Migration[8.1]
  def change
    validate_check_constraint :feed_twitch_settings, name: "feed_twitch_settings_switched_away_check"
  end
end
