# frozen_string_literal: true

class AddDispatchTrackingAndFeedPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :integration_events, :dispatched_at, :datetime

    create_table :feed_posts, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :subscription, null: false, type: :string, index: false, foreign_key: {to_table: :feed_subscriptions}
      t.string :story_key, null: false
      t.string :event_id
      t.bigint :discord_channel_id
      t.bigint :discord_message_id
      t.timestamps
    end
    add_index :feed_posts, [:subscription_id, :story_key], unique: true

    reversible do |dir|
      dir.up do
        safety_assured do
          execute "ALTER TABLE feed_posts ALTER COLUMN id SET DEFAULT ('fdp_' || gen_random_uuid())"
        end
      end
    end
  end
end
