# frozen_string_literal: true

class CreateReminders < ActiveRecord::Migration[8.1]
  def change
    create_table :reminders, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.bigint :server_id # null = DM reminder
      t.bigint :user_id, null: false
      t.bigint :channel_id, null: false
      t.datetime :remind_at, null: false
      t.text :message, null: false
      t.boolean :deliver_via_dm, null: false, default: false
      t.timestamps
    end
    add_index :reminders, :remind_at

    reversible do |dir|
      dir.up { execute "ALTER TABLE reminders ALTER COLUMN id SET DEFAULT ('rmd_' || gen_random_uuid())" }
    end
  end
end
