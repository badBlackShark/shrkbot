# frozen_string_literal: true

class CreateTwilightStruggleGames < ActiveRecord::Migration[8.1]
  def change
    create_table :twilight_struggle_games, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.string :external_id, null: false
      t.references :tournament, null: false, foreign_key: {to_table: :twilight_struggle_tournaments}, type: :string
      t.bigint :discord_channel_id
      t.bigint :discord_message_id
      t.timestamps
    end

    add_index :twilight_struggle_games, :external_id, unique: true

    reversible do |dir|
      dir.up { safety_assured { execute "ALTER TABLE twilight_struggle_games ALTER COLUMN id SET DEFAULT ('tsg_' || gen_random_uuid())" } }
    end
  end
end
