# frozen_string_literal: true

class ValidateNumericExternalIdConstraints < ActiveRecord::Migration[8.1]
  def change
    validate_check_constraint :twilight_struggle_games, name: "twilight_struggle_games_external_id_numeric"
    validate_check_constraint :twilight_struggle_tournaments, name: "twilight_struggle_tournaments_external_id_numeric"
  end
end
