# frozen_string_literal: true

class CreateFeedTwitchSettings < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      create_table :feed_twitch_settings, id: false do |t|
        t.string :id, null: false, primary_key: true
        t.references :subscription, null: false, type: :string, index: {unique: true}, foreign_key: {to_table: :feed_subscriptions}
        t.bigint :live_role_id
        t.boolean :show_viewers, null: false, default: true
        t.timestamps
      end
      execute "ALTER TABLE feed_twitch_settings ALTER COLUMN id SET DEFAULT ('fts_' || gen_random_uuid())"
    end
  end

  def down
    drop_table :feed_twitch_settings
  end
end
