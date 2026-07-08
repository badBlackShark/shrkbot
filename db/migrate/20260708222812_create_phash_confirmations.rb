# frozen_string_literal: true

class CreatePhashConfirmations < ActiveRecord::Migration[8.1]
  def change
    create_table :phash_confirmations, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :phash, null: false, foreign_key: true, type: :string, index: false
      t.references :server_configuration, null: false, foreign_key: true, type: :string
      t.string :verdict, null: false
      t.timestamps
    end
    add_index :phash_confirmations, [:phash_id, :server_configuration_id], unique: true

    reversible do |dir|
      dir.up do
        execute "ALTER TABLE phash_confirmations ALTER COLUMN id SET DEFAULT ('phc_' || gen_random_uuid())"
      end
    end

    add_check_constraint :phash_confirmations, "verdict IN ('confirmed', 'dismissed')", name: "phash_confirmations_verdict_check"
  end
end
