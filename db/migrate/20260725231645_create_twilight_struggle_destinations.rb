# frozen_string_literal: true

class CreateTwilightStruggleDestinations < ActiveRecord::Migration[8.1]
  def change
    create_table :twilight_struggle_destinations, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :tournament, null: false, foreign_key: {to_table: :twilight_struggle_tournaments}, type: :string, index: false
      t.references :server_configuration, null: false, foreign_key: true, type: :string
      t.bigint :discord_channel_id
      t.text :template_win
      t.text :template_tie
      t.text :template_video
      t.boolean :ping_players
      t.datetime :archived_at
      t.timestamps
    end

    add_index :twilight_struggle_destinations,
      [:tournament_id, :server_configuration_id],
      unique: true,
      name: "index_twilight_struggle_destinations_on_tournament_and_server"

    reversible do |dir|
      dir.up do
        safety_assured do
          execute "ALTER TABLE twilight_struggle_destinations ALTER COLUMN id SET DEFAULT ('tsd_' || gen_random_uuid())"

          execute <<~SQL
            INSERT INTO twilight_struggle_destinations
              (tournament_id, server_configuration_id, discord_channel_id,
               template_win, template_tie, template_video, ping_players, archived_at,
               created_at, updated_at)
            SELECT id, server_configuration_id, discord_channel_id,
                   template_win, template_tie, template_video, ping_players, archived_at,
                   NOW(), NOW()
            FROM twilight_struggle_tournaments
            WHERE server_configuration_id IS NOT NULL
          SQL
        end
      end
    end
  end
end
