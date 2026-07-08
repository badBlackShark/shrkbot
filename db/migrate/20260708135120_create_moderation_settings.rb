# frozen_string_literal: true

class CreateModerationSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :moderation_settings, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :server_configuration, null: false, foreign_key: true, type: :string, index: {unique: true}
      t.bigint :staff_role_id
      t.timestamps
    end

    reversible do |dir|
      dir.up { execute "ALTER TABLE moderation_settings ALTER COLUMN id SET DEFAULT ('mds_' || gen_random_uuid())" }
    end
  end
end
