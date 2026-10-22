# frozen_string_literal: true

class AddPostDelayToTwilightStruggle < ActiveRecord::Migration[8.1]
  def change
    add_column :twilight_struggle_games, :revision, :integer, default: 0, null: false
    add_column :twilight_struggle_destinations, :post_delay_seconds, :integer
    safety_assured do
      add_check_constraint :twilight_struggle_destinations,
        "post_delay_seconds IS NULL OR (post_delay_seconds >= 0 AND post_delay_seconds <= 604800)",
        name: "twilight_struggle_destinations_post_delay_seconds_check"
    end
  end
end
