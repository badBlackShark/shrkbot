# frozen_string_literal: true

module TwilightStruggle
  class Destination < ApplicationRecord
    self.table_name = "twilight_struggle_destinations"

    belongs_to :tournament, class_name: "TwilightStruggle::Tournament"
    belongs_to :server_configuration

    scope :active, -> { where(active: true) }

    validates :tournament_id, uniqueness: {scope: :server_configuration_id}

    def manually_archived?
      archived_at.present?
    end

    def archived?
      active? && manually_archived?
    end
  end
end
