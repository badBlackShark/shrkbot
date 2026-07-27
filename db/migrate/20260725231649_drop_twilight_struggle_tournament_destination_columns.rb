# frozen_string_literal: true

class DropTwilightStruggleTournamentDestinationColumns < ActiveRecord::Migration[8.1]
  def up
    safety_assured do
      remove_reference :twilight_struggle_tournaments, :server_configuration, type: :string, foreign_key: true
      remove_column :twilight_struggle_tournaments, :discord_channel_id
      remove_column :twilight_struggle_tournaments, :template_win
      remove_column :twilight_struggle_tournaments, :template_tie
      remove_column :twilight_struggle_tournaments, :template_video
      remove_column :twilight_struggle_tournaments, :ping_players
      remove_column :twilight_struggle_tournaments, :archived_at
      remove_column :twilight_struggle_games, :discord_channel_id
      remove_column :twilight_struggle_games, :discord_message_id
    end
  end
end
