# frozen_string_literal: true

class CreateFeedTables < ActiveRecord::Migration[8.1]
  def change
    create_table :feed_subscriptions, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :server_configuration, null: false, type: :string, index: false, foreign_key: true
      t.references :watch, null: false, type: :string, foreign_key: {to_table: :integration_watches}
      t.bigint :channel_id, null: false
      t.bigint :role_id
      t.string :body_length, null: false, default: "preview"
      t.timestamps
    end
    add_index :feed_subscriptions, [:server_configuration_id, :watch_id], unique: true

    create_table :feed_subscribed_events, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :subscription, null: false, type: :string, index: false, foreign_key: {to_table: :feed_subscriptions}
      t.string :event_type, null: false
      t.text :template
      t.timestamps
    end
    add_index :feed_subscribed_events, [:subscription_id, :event_type], unique: true

    reversible do |dir|
      dir.up do
        safety_assured do
          execute "ALTER TABLE feed_subscriptions ALTER COLUMN id SET DEFAULT ('fds_' || gen_random_uuid())"
          execute "ALTER TABLE feed_subscribed_events ALTER COLUMN id SET DEFAULT ('fse_' || gen_random_uuid())"
        end
      end
    end
  end
end
