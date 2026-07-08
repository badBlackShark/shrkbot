# frozen_string_literal: true

class CreateSpamProtectionSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :spam_protection_settings, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :server_configuration, null: false, foreign_key: true, type: :string, index: {unique: true}
      t.integer :channel_threshold, null: false, default: 4
      t.integer :window_seconds, null: false, default: 15
      t.float :similarity, null: false, default: 1.0
      t.boolean :match_symbol_only_messages, null: false, default: false
      t.string :action, null: false, default: "purge"
      t.string :punishment, null: false, default: "none"
      t.integer :timeout_seconds, null: false, default: 3600
      t.timestamps
    end

    add_check_constraint :spam_protection_settings, "channel_threshold >= 2 AND channel_threshold <= 500", name: "spam_protection_settings_channel_threshold_check"
    add_check_constraint :spam_protection_settings, "window_seconds >= 1 AND window_seconds <= 60", name: "spam_protection_settings_window_seconds_check"
    add_check_constraint :spam_protection_settings, "similarity >= 0.75 AND similarity <= 1.0", name: "spam_protection_settings_similarity_check"
    add_check_constraint :spam_protection_settings, "action IN ('purge', 'notify_only')", name: "spam_protection_settings_action_check"
    add_check_constraint :spam_protection_settings, "punishment IN ('none', 'timeout', 'kick', 'ban')", name: "spam_protection_settings_punishment_check"
    add_check_constraint :spam_protection_settings, "timeout_seconds >= 60 AND timeout_seconds <= 2419200", name: "spam_protection_settings_timeout_seconds_check"

    reversible do |dir|
      dir.up { execute "ALTER TABLE spam_protection_settings ALTER COLUMN id SET DEFAULT ('sps_' || gen_random_uuid())" }
    end
  end
end
