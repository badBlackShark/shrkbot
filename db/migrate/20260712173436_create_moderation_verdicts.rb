# frozen_string_literal: true

class CreateModerationVerdicts < ActiveRecord::Migration[8.1]
  def change
    create_table :moderation_verdicts, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :server_configuration, null: false, foreign_key: true, type: :string, index: false
      t.bigint :discord_user_id, null: false
      t.string :action, null: false
      t.string :punishment, null: false, default: "none"
      t.string :phash
      t.bigint :log_channel_id
      t.bigint :log_message_id
      t.datetime :reversed_at
      t.timestamps
    end

    reversible do |dir|
      dir.up do
        execute "ALTER TABLE moderation_verdicts ALTER COLUMN id SET DEFAULT ('mvr_' || gen_random_uuid())"
      end
    end

    add_index :moderation_verdicts, [:server_configuration_id, :created_at]
    add_index :moderation_verdicts, :discord_user_id

    add_check_constraint :moderation_verdicts, "action IN ('flag_for_review', 'remove')", name: "moderation_verdicts_action_check"
    add_check_constraint :moderation_verdicts, "punishment IN ('none', 'timeout', 'kick', 'ban')", name: "moderation_verdicts_punishment_check"
  end
end
