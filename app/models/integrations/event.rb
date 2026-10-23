# frozen_string_literal: true

module Integrations
  class Event < ApplicationRecord
    self.table_name = "integration_events"

    belongs_to :watch

    validates :type, :subject_key, :occurred_at, presence: true
  end
end
