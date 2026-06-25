# frozen_string_literal: true

class CreatePlugins < ActiveRecord::Migration[8.1]
  def change
    create_table :plugins, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.string :key, null: false
      t.string :name, null: false
      t.text :description
      t.boolean :default_enabled, null: false, default: false
      t.timestamps
    end
    add_index :plugins, :key, unique: true

    reversible do |dir|
      dir.up { execute "ALTER TABLE plugins ALTER COLUMN id SET DEFAULT ('plg_' || gen_random_uuid())" }
    end
  end
end
