# frozen_string_literal: true

class CreateAssignableRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :assignable_roles, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :role_setting, null: false, foreign_key: true, type: :string
      t.bigint :role_id, null: false
      t.string :label
      t.string :description
      t.string :emoji
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :assignable_roles, %i[role_setting_id role_id], unique: true

    reversible do |dir|
      dir.up { execute "ALTER TABLE assignable_roles ALTER COLUMN id SET DEFAULT ('asr_' || gen_random_uuid())" }
    end
  end
end
