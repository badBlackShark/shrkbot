# frozen_string_literal: true

class CreatePhashes < ActiveRecord::Migration[8.1]
  def change
    create_table :phashes, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.string :phash, null: false, limit: 16
      t.datetime :last_seen_at, null: false
      t.timestamps
    end
    add_index :phashes, :phash, unique: true

    reversible do |dir|
      dir.up { execute "ALTER TABLE phashes ALTER COLUMN id SET DEFAULT ('phs_' || gen_random_uuid())" }
    end
  end
end
