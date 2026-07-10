# frozen_string_literal: true

module Moderation
  class PhashConfirmation < ApplicationRecord
    self.table_name = "phash_confirmations"

    belongs_to :phash, class_name: "Moderation::Phash"
    belongs_to :server_configuration

    validates :verdict, presence: true
    string_enum :verdict, %w[confirmed dismissed], validate: {allow_nil: true}
  end
end
