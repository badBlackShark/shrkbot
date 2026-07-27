# frozen_string_literal: true

class CreateTwilightStruggleTournamentAdmins < ActiveRecord::Migration[8.1]
  def change
    create_table :twilight_struggle_tournament_admins, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :tournament, null: false, foreign_key: {to_table: :twilight_struggle_tournaments}, type: :string, index: false
      t.bigint :discord_id, null: false
      t.timestamps
    end

    add_index :twilight_struggle_tournament_admins,
      [:tournament_id, :discord_id],
      unique: true,
      name: "index_ts_tournament_admins_on_tournament_and_discord_id"
    add_index :twilight_struggle_tournament_admins, :discord_id

    reversible do |dir|
      dir.up { safety_assured { execute "ALTER TABLE twilight_struggle_tournament_admins ALTER COLUMN id SET DEFAULT ('tsa_' || gen_random_uuid())" } }
    end
  end
end
