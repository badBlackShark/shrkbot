# frozen_string_literal: true

module Moderation
  class VerdictRecord < ApplicationRecord
    self.table_name = "moderation_verdicts"

    belongs_to :server_configuration

    validates :discord_user_id, presence: true
    validates :action, presence: true
    validates :punishment, presence: true
    string_enum :action, %w[flag_for_review remove]
    string_enum :punishment, %w[none timeout kick ban], prefix: true

    scope :for_user, ->(discord_user_id) { where(discord_user_id:) }
    scope :recent, -> { order(created_at: :desc) }
  end
end
