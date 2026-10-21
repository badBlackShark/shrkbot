# frozen_string_literal: true

module TwilightStruggle
  class Destination < ApplicationRecord
    self.table_name = "twilight_struggle_destinations"

    DEFAULT_PLAYER_DISPLAY = "name"
    PLAYER_DISPLAYS = [DEFAULT_PLAYER_DISPLAY, "name_and_tag", "tag"].freeze
    MAX_POST_DELAY = 1.week

    string_enum :player_display, PLAYER_DISPLAYS, validate: {allow_nil: true}, prefix: true

    belongs_to :tournament, class_name: "TwilightStruggle::Tournament"
    belongs_to :server_configuration

    scope :active, -> { where(active: true) }

    validates :tournament_id, uniqueness: {scope: :server_configuration_id}
    validates :post_delay_seconds, numericality: {only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: MAX_POST_DELAY.to_i}, allow_nil: true

    def manually_archived?
      archived_at.present?
    end

    def archived?
      active? && manually_archived?
    end
  end
end
