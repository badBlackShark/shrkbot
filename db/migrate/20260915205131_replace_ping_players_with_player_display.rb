# frozen_string_literal: true

class ReplacePingPlayersWithPlayerDisplay < ActiveRecord::Migration[8.1]
  def up
    add_column :twilight_struggle_destinations, :player_display, :string
    safety_assured do
      execute(<<~SQL)
        UPDATE twilight_struggle_destinations
        SET player_display = CASE WHEN ping_players THEN 'name_and_tag' ELSE 'name' END
        WHERE ping_players IS NOT NULL
      SQL
    end
    safety_assured do
      add_check_constraint :twilight_struggle_destinations,
        "player_display IN ('name', 'name_and_tag', 'tag')",
        name: "twilight_struggle_destinations_player_display_check"
    end
    safety_assured { remove_column :twilight_struggle_destinations, :ping_players }
  end

  def down
    add_column :twilight_struggle_destinations, :ping_players, :boolean
    safety_assured do
      execute("UPDATE twilight_struggle_destinations SET ping_players = (player_display <> 'name') WHERE player_display IS NOT NULL")
    end
    safety_assured { remove_column :twilight_struggle_destinations, :player_display }
  end
end
