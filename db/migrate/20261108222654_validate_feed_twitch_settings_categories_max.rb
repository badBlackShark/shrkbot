# frozen_string_literal: true

class ValidateFeedTwitchSettingsCategoriesMax < ActiveRecord::Migration[8.1]
  def change
    validate_check_constraint :feed_twitch_settings, name: "feed_twitch_settings_categories_max"
  end
end
