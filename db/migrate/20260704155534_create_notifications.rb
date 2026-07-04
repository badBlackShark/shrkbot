# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :server_configuration, null: false, foreign_key: true, type: :string, index: false
      t.string :kind, null: false
      t.jsonb :data, null: false, default: {}
      t.datetime :read_at
      t.datetime :dismissed_at
      t.timestamps
    end
    add_index :notifications, [:server_configuration_id, :created_at]

    reversible do |dir|
      dir.up { execute "ALTER TABLE notifications ALTER COLUMN id SET DEFAULT ('ntf_' || gen_random_uuid())" }
    end
  end
end
