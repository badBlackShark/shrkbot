# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :server_configuration

  validates :kind, presence: true

  scope :active, -> { where(dismissed_at: nil) }
  scope :unread, -> { where(read_at: nil, dismissed_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
end
