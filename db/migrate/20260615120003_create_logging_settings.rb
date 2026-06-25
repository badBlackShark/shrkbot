# frozen_string_literal: true

class CreateLoggingSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :logging_settings, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :server_configuration, null: false, foreign_key: true, type: :string, index: {unique: true}
      t.bigint :channel_id
      t.timestamps
    end

    reversible do |dir|
      dir.up { execute "ALTER TABLE logging_settings ALTER COLUMN id SET DEFAULT ('lgs_' || gen_random_uuid())" }
    end
  end
end
