# frozen_string_literal: true

class ValidateFeedTwitchSettingsCategoriesArray < ActiveRecord::Migration[8.1]
  def change
    validate_check_constraint :feed_twitch_settings, name: "feed_twitch_settings_categories_array"
  end
end
