# frozen_string_literal: true

module Moderation
  class Settings < ApplicationRecord
    self.table_name = "moderation_settings"

    belongs_to :server_configuration

    validates :new_account_age_days,
      numericality: {only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 365}
  end
end
