# frozen_string_literal: true

class CreateFeedTwitchCategorySettings < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      create_table :feed_twitch_category_settings, id: false do |t|
        t.string :id, null: false, primary_key: true
        t.references :subscription, null: false, type: :string, index: {unique: true}, foreign_key: {to_table: :feed_subscriptions}
        t.bigint :role_id
        t.integer :min_viewers, null: false, default: 0
        t.jsonb :languages, null: false, default: []
        t.jsonb :excluded_channels, null: false, default: []
        t.string :live_end_mode, null: false, default: "mark_ended_with_vod"
        t.string :switched_away, null: false, default: "summary"
        t.boolean :show_viewers, null: false, default: true
        t.boolean :show_preview_frame, null: false, default: true
        t.timestamps

        t.check_constraint "min_viewers >= 0", name: "feed_twitch_category_settings_min_viewers_check"
        t.check_constraint "jsonb_typeof(languages) = 'array'", name: "feed_twitch_category_settings_languages_array"
        t.check_constraint "jsonb_array_length(languages) <= 50", name: "feed_twitch_category_settings_languages_max"
        t.check_constraint "jsonb_typeof(excluded_channels) = 'array'", name: "feed_twitch_category_settings_excluded_channels_array"
        t.check_constraint "jsonb_array_length(excluded_channels) <= 100", name: "feed_twitch_category_settings_excluded_channels_max"
        t.check_constraint "live_end_mode IN ('keep', 'delete', 'mark_ended', 'mark_ended_with_vod')", name: "feed_twitch_category_settings_live_end_mode_check"
        t.check_constraint "switched_away IN ('summary', 'delete')", name: "feed_twitch_category_settings_switched_away_check"
      end
      execute "ALTER TABLE feed_twitch_category_settings ALTER COLUMN id SET DEFAULT ('ftcs_' || gen_random_uuid())"
    end
  end

  def down
    drop_table :feed_twitch_category_settings
  end
end
