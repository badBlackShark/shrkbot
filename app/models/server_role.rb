# frozen_string_literal: true

class ServerRole < ApplicationRecord
  belongs_to :server_configuration

  validates :discord_id, presence: true, uniqueness: {scope: :server_configuration_id}
  validates :name, presence: true
end
