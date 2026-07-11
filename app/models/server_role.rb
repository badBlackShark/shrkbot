# frozen_string_literal: true

class ServerRole < ApplicationRecord
  belongs_to :server_configuration

  validates :discord_id, presence: true, uniqueness: {scope: :server_configuration_id}
  validates :name, presence: true

  MANAGE_MESSAGES = 1 << 13
  ADMINISTRATOR = 1 << 3

  def manage_messages?
    permissions.anybits?(MANAGE_MESSAGES | ADMINISTRATOR)
  end
end
