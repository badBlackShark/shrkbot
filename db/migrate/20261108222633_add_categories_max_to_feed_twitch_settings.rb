# frozen_string_literal: true

class AddCategoriesMaxToFeedTwitchSettings < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :feed_twitch_settings,
      "jsonb_array_length(categories) <= 100",
      name: "feed_twitch_settings_categories_max",
      validate: false
  end
end
