# frozen_string_literal: true

class AddNumericExternalIdConstraints < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint(
      :twilight_struggle_games,
      "external_id ~ '^[0-9]+$'",
      name: "twilight_struggle_games_external_id_numeric",
      validate: false
    )
    add_check_constraint(
      :twilight_struggle_tournaments,
      "external_id IS NULL OR external_id ~ '^[0-9]+$'",
      name: "twilight_struggle_tournaments_external_id_numeric",
      validate: false
    )
  end
end
