# frozen_string_literal: true

module Moderation
  class Phash < ApplicationRecord
    self.table_name = "phashes"

    has_many :phash_confirmations, dependent: :delete_all

    validates :phash, presence: true, uniqueness: true, length: {maximum: 16}
    validates :last_seen_at, presence: true
  end
end
