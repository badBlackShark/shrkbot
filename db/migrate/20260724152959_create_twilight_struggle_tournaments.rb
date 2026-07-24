# frozen_string_literal: true

class CreateTwilightStruggleTournaments < ActiveRecord::Migration[8.1]
  def change
    create_table :twilight_struggle_tournaments, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.string :external_id
      t.string :name, null: false
      t.references :parent, foreign_key: {to_table: :twilight_struggle_tournaments}, type: :string, index: true
      t.boolean :friendly, null: false, default: false
      t.string :status
      t.datetime :archived_at
      t.timestamps
    end

    add_index :twilight_struggle_tournaments, :external_id, unique: true, where: "external_id IS NOT NULL"
    add_index :twilight_struggle_tournaments, :friendly, unique: true, where: "friendly"

    add_check_constraint :twilight_struggle_tournaments,
      "(friendly AND external_id IS NULL) OR (NOT friendly AND external_id IS NOT NULL)",
      name: "twilight_struggle_tournaments_friendly_external_id_check"

    reversible do |dir|
      dir.up { safety_assured { execute "ALTER TABLE twilight_struggle_tournaments ALTER COLUMN id SET DEFAULT ('tst_' || gen_random_uuid())" } }
    end
  end
end
