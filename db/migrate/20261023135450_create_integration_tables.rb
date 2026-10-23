# frozen_string_literal: true

class CreateIntegrationTables < ActiveRecord::Migration[8.1]
  def change
    create_table :integration_watches, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.string :watcher, null: false
      t.string :external_id, null: false
      t.string :name, null: false
      t.datetime :primed_at
      t.datetime :polled_at
      t.datetime :failing_since
      t.datetime :broken_reported_at
      t.string :last_error
      t.timestamps
    end
    add_index :integration_watches, [:watcher, :external_id], unique: true

    create_table :integration_seen_items, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :watch, null: false, type: :string, index: false, foreign_key: {to_table: :integration_watches}
      t.string :external_id, null: false
      t.timestamps
    end
    add_index :integration_seen_items, [:watch_id, :external_id], unique: true

    create_table :integration_events, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.string :type, null: false
      t.references :watch, null: false, type: :string, index: false, foreign_key: {to_table: :integration_watches}
      t.string :subject_key, null: false
      t.datetime :occurred_at, null: false
      t.jsonb :payload, null: false, default: {}
      t.timestamps
    end
    add_index :integration_events, [:watch_id, :type, :subject_key], unique: true

    reversible do |dir|
      dir.up do
        safety_assured do
          execute "ALTER TABLE integration_watches ALTER COLUMN id SET DEFAULT ('itw_' || gen_random_uuid())"
          execute "ALTER TABLE integration_seen_items ALTER COLUMN id SET DEFAULT ('its_' || gen_random_uuid())"
          execute "ALTER TABLE integration_events ALTER COLUMN id SET DEFAULT ('ite_' || gen_random_uuid())"
        end
      end
    end
  end
end
