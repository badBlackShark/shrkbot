# frozen_string_literal: true

class AddPostingConfigToTwilightStruggleTournaments < ActiveRecord::Migration[8.1]
  def change
    safety_assured do
      add_reference :twilight_struggle_tournaments, :server_configuration, type: :string, null: true, foreign_key: true
    end
    add_column :twilight_struggle_tournaments, :discord_channel_id, :bigint
    add_column :twilight_struggle_tournaments, :template_with_video, :text
    add_column :twilight_struggle_tournaments, :template_without_video, :text
    add_column :twilight_struggle_tournaments, :ping_players, :boolean
  end
end
