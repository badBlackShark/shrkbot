# frozen_string_literal: true

module TwilightStruggle
  class Game < ApplicationRecord
    self.table_name = "twilight_struggle_games"

    belongs_to :tournament, class_name: "TwilightStruggle::Tournament"
    has_many :posted_messages, class_name: "TwilightStruggle::PostedMessage", dependent: :delete_all

    validates :external_id, presence: true, uniqueness: true
  end
end
