# frozen_string_literal: true

class ValidateFeedTwitchSettingsLiveEndMode < ActiveRecord::Migration[8.1]
  def change
    validate_check_constraint :feed_twitch_settings, name: "feed_twitch_settings_live_end_mode_check"
  end
end
