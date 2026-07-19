# frozen_string_literal: true

class CreateLfgSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :lfg_settings, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :server_configuration, null: false, foreign_key: true, type: :string, index: {unique: true}
      t.integer :cooldown_seconds, null: false, default: 300
      t.integer :post_lifetime_minutes, null: false, default: 360
      t.integer :default_min_membership_days
      t.bigint :default_required_role_ids, array: true, null: false, default: []
      t.bigint :default_excluded_role_ids, array: true, null: false, default: []
      t.bigint :allowed_channel_ids, array: true, null: false, default: []
      t.timestamps
    end

    add_check_constraint :lfg_settings, "cooldown_seconds >= 0 AND cooldown_seconds <= 86400", name: "lfg_settings_cooldown_seconds_check"
    add_check_constraint :lfg_settings, "post_lifetime_minutes >= 5 AND post_lifetime_minutes <= 10080", name: "lfg_settings_post_lifetime_minutes_check"
    add_check_constraint :lfg_settings, "default_min_membership_days IS NULL OR (default_min_membership_days >= 0 AND default_min_membership_days <= 3650)", name: "lfg_settings_min_membership_days_check"
    add_check_constraint :lfg_settings, "cardinality(default_required_role_ids) <= 50", name: "lfg_settings_required_role_ids_count_check"
    add_check_constraint :lfg_settings, "cardinality(default_excluded_role_ids) <= 50", name: "lfg_settings_excluded_role_ids_count_check"
    add_check_constraint :lfg_settings, "cardinality(allowed_channel_ids) <= 50", name: "lfg_settings_allowed_channel_ids_count_check"

    reversible do |dir|
      dir.up { safety_assured { execute "ALTER TABLE lfg_settings ALTER COLUMN id SET DEFAULT ('lfs_' || gen_random_uuid())" } }
    end
  end
end
