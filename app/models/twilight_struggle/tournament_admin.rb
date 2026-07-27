# frozen_string_literal: true

module TwilightStruggle
  class TournamentAdmin < ApplicationRecord
    self.table_name = "twilight_struggle_tournament_admins"

    belongs_to :tournament, class_name: "TwilightStruggle::Tournament"

    validates :discord_id, presence: true, uniqueness: {scope: :tournament_id}
  end
end
