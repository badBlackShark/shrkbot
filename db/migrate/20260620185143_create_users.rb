# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.bigint :discord_id, null: false, index: {unique: true}
      t.string :username, null: false
      t.timestamps
    end

    reversible do |dir|
      dir.up { execute "ALTER TABLE users ALTER COLUMN id SET DEFAULT ('usr_' || gen_random_uuid())" }
    end
  end
end
