# frozen_string_literal: true

class CreateRoleSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :role_settings, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :server_configuration, null: false, foreign_key: true, type: :string, index: {unique: true}
      t.bigint :channel_id
      t.bigint :message_id
      t.boolean :notify_on_assign, null: false, default: false
      t.boolean :log_on_assign, null: false, default: false
      t.timestamps
    end

    reversible do |dir|
      dir.up { execute "ALTER TABLE role_settings ALTER COLUMN id SET DEFAULT ('rls_' || gen_random_uuid())" }
    end
  end
end
