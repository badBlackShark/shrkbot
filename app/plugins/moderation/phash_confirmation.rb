# frozen_string_literal: true

module Moderation
  class PhashConfirmation < ApplicationRecord
    self.table_name = "phash_confirmations"

    VERDICTS = %w[confirmed dismissed].freeze

    belongs_to :phash, class_name: "Moderation::Phash"
    belongs_to :server_configuration

    validates :verdict, presence: true, inclusion: {in: VERDICTS}
  end
end
