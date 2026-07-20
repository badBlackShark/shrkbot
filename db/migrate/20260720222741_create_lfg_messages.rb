# frozen_string_literal: true

class CreateLfgMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :lfg_messages, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :server_configuration, null: false, foreign_key: true, type: :string
      t.bigint :channel_id, null: false
      t.bigint :message_id, null: false
      t.bigint :notify_reply_id
      t.bigint :start_ping_id
      t.timestamps
    end

    add_index :lfg_messages, :message_id, unique: true

    reversible do |dir|
      dir.up { safety_assured { execute "ALTER TABLE lfg_messages ALTER COLUMN id SET DEFAULT ('lfm_' || gen_random_uuid())" } }
    end
  end
end
