# frozen_string_literal: true

module TwilightStruggle
  class Game < ApplicationRecord
    self.table_name = "twilight_struggle_games"

    belongs_to :tournament, class_name: "TwilightStruggle::Tournament"

    validates :external_id, presence: true, uniqueness: true
  end
end
