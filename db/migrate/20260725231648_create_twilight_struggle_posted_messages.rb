# frozen_string_literal: true

class CreateTwilightStrugglePostedMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :twilight_struggle_posted_messages, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :game, null: false, foreign_key: {to_table: :twilight_struggle_games}, type: :string, index: false
      t.references :server_configuration, null: false, foreign_key: true, type: :string
      t.bigint :discord_channel_id, null: false
      t.bigint :discord_message_id, null: false
      t.timestamps
    end

    add_index :twilight_struggle_posted_messages,
      [:game_id, :server_configuration_id],
      unique: true,
      name: "index_twilight_struggle_posted_messages_on_game_and_server"

    reversible do |dir|
      dir.up do
        safety_assured do
          execute "ALTER TABLE twilight_struggle_posted_messages ALTER COLUMN id SET DEFAULT ('tsm_' || gen_random_uuid())"

          execute <<~SQL
            INSERT INTO twilight_struggle_posted_messages
              (game_id, server_configuration_id, discord_channel_id, discord_message_id,
               created_at, updated_at)
            SELECT g.id, sc.server_configuration_id, g.discord_channel_id, g.discord_message_id,
                   NOW(), NOW()
            FROM twilight_struggle_games g
            JOIN server_channels sc ON sc.discord_id = g.discord_channel_id
            WHERE g.discord_message_id IS NOT NULL
          SQL
        end
      end
    end
  end
end
