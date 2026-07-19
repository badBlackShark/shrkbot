# frozen_string_literal: true

class CreateLfgPingableRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :lfg_pingable_roles, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :lfg_settings, null: false, foreign_key: true, type: :string, index: false
      t.bigint :role_id, null: false
      t.integer :min_membership_days
      t.bigint :required_role_ids, array: true
      t.bigint :excluded_role_ids, array: true
      t.bigint :allowed_channel_ids, array: true
      t.timestamps
    end

    add_index :lfg_pingable_roles, [:lfg_settings_id, :role_id], unique: true

    add_check_constraint :lfg_pingable_roles, "min_membership_days IS NULL OR (min_membership_days >= 0 AND min_membership_days <= 3650)", name: "lfg_pingable_roles_min_membership_days_check"
    add_check_constraint :lfg_pingable_roles, "required_role_ids IS NULL OR cardinality(required_role_ids) <= 50", name: "lfg_pingable_roles_required_role_ids_count_check"
    add_check_constraint :lfg_pingable_roles, "excluded_role_ids IS NULL OR cardinality(excluded_role_ids) <= 50", name: "lfg_pingable_roles_excluded_role_ids_count_check"
    add_check_constraint :lfg_pingable_roles, "allowed_channel_ids IS NULL OR (cardinality(allowed_channel_ids) >= 1 AND cardinality(allowed_channel_ids) <= 50)", name: "lfg_pingable_roles_allowed_channel_ids_check"

    reversible do |dir|
      dir.up { safety_assured { execute "ALTER TABLE lfg_pingable_roles ALTER COLUMN id SET DEFAULT ('lfr_' || gen_random_uuid())" } }
    end
  end
end
