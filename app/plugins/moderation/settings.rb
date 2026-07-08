# frozen_string_literal: true

module Moderation
  class Settings < ApplicationRecord
    self.table_name = "moderation_settings"

    belongs_to :server_configuration
  end
end
