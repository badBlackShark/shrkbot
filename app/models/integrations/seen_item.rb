# frozen_string_literal: true

module Integrations
  class SeenItem < ApplicationRecord
    self.table_name = "integration_seen_items"

    belongs_to :watch

    validates :external_id, presence: true
  end
end
