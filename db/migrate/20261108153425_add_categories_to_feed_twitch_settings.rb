# frozen_string_literal: true

class AddCategoriesToFeedTwitchSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :feed_twitch_settings, :categories, :jsonb, default: [], null: false
    add_check_constraint(
      :feed_twitch_settings,
      "jsonb_typeof(categories) = 'array'",
      name: "feed_twitch_settings_categories_array",
      validate: false
    )
  end
end
