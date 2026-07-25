# frozen_string_literal: true

module TwilightStruggle
  class Tournament < ApplicationRecord
    self.table_name = "twilight_struggle_tournaments"

    CLOSED_STATUS = "closed"

    belongs_to :parent, class_name: "TwilightStruggle::Tournament", optional: true
    belongs_to :server_configuration, optional: true
    has_many :children, class_name: "TwilightStruggle::Tournament", foreign_key: :parent_id, inverse_of: :parent, dependent: :destroy
    has_many :games, class_name: "TwilightStruggle::Game", dependent: :delete_all

    scope :unarchived, -> { where(archived_at: nil).where("status IS DISTINCT FROM ?", CLOSED_STATUS) }
    scope :archived, -> { where.not(archived_at: nil).or(where(status: CLOSED_STATUS)) }
    scope :unclaimed, -> { where(server_configuration_id: nil) }

    validates :name, presence: true
    validates :friendly, inclusion: {in: [true, false]}
    validates :external_id, uniqueness: true, allow_nil: true
    validates :external_id, presence: true, unless: :friendly?
    validates :external_id, absence: true, if: :friendly?
    validate :parent_chain_must_not_cycle

    def archived?
      manually_archived? || closed_upstream?
    end

    def manually_archived?
      archived_at.present?
    end

    def closed_upstream?
      status == CLOSED_STATUS
    end

    def claimed?
      server_configuration_id.present?
    end

    private

    def parent_chain_must_not_cycle
      return if parent.nil?

      seen = [id]
      current = parent

      while current
        return errors.add(:parent, "would create a loop") if seen.include?(current.id)

        seen << current.id
        current = current.parent
      end
    end
  end
end
