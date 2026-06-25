# frozen_string_literal: true

class CreateBotSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :bot_settings, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.string :key, null: false
      t.string :value
      t.timestamps
    end
    add_index :bot_settings, :key, unique: true

    reversible do |dir|
      dir.up do
        execute "ALTER TABLE bot_settings ALTER COLUMN id SET DEFAULT ('bst_' || gen_random_uuid())"
      end
    end
  end
end
