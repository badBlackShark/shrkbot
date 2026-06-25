# frozen_string_literal: true

class CreateChannelOverwrites < ActiveRecord::Migration[8.1]
  def change
    create_table :channel_overwrites, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :server_channel, null: false, foreign_key: true, type: :string, index: false
      t.bigint :target_id, null: false
      t.string :target_type, null: false
      t.bigint :allow, null: false, default: 0
      t.bigint :deny, null: false, default: 0
      t.timestamps
      t.index [:server_channel_id, :target_id], unique: true
    end

    reversible do |dir|
      dir.up { execute "ALTER TABLE channel_overwrites ALTER COLUMN id SET DEFAULT ('cov_' || gen_random_uuid())" }
    end

    add_check_constraint :channel_overwrites, "target_type IN ('role', 'member')", name: "channel_overwrites_target_type_check"
  end
end
