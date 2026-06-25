# frozen_string_literal: true

class RestructureRolesForMultipleSets < ActiveRecord::Migration[8.1]
  def up
    remove_column :role_settings, :message_id

    create_table :role_sets, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :role_setting, null: false, foreign_key: true, type: :string, index: true
      t.string :name, null: false
      t.bigint :channel_override
      t.string :selection_mode, null: false
      t.bigint :message_id
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    execute "ALTER TABLE role_sets ALTER COLUMN id SET DEFAULT ('rst_' || gen_random_uuid())"
    add_check_constraint :role_sets, "selection_mode IN ('single', 'multi')", name: "role_sets_selection_mode_check"

    # Repoint assignable_roles from role_setting to role_set. Disposable test
    # config (greenfield), so clear the table rather than backfill a set per row.
    execute "DELETE FROM assignable_roles"
    remove_foreign_key :assignable_roles, :role_settings
    remove_index :assignable_roles, column: [:role_setting_id, :role_id]
    remove_column :assignable_roles, :role_setting_id
    add_reference :assignable_roles, :role_set, null: false, foreign_key: true, type: :string, index: false
    add_index :assignable_roles, [:role_set_id, :role_id], unique: true
  end

  def down
    execute "DELETE FROM assignable_roles"
    remove_index :assignable_roles, column: [:role_set_id, :role_id]
    remove_reference :assignable_roles, :role_set, foreign_key: true
    add_reference :assignable_roles, :role_setting, null: false, foreign_key: true, type: :string, index: false
    add_index :assignable_roles, [:role_setting_id, :role_id], unique: true

    drop_table :role_sets
    add_column :role_settings, :message_id, :bigint
  end
end
