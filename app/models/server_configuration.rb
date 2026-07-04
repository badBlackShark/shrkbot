# frozen_string_literal: true

class ServerConfiguration < ApplicationRecord
  has_many :plugin_activations, dependent: :delete_all
  has_many :plugins, through: :plugin_activations

  has_one :logging_setting, dependent: :delete
  has_one :role_setting, class_name: "Roles::Settings", dependent: :destroy
  has_one :welcome_settings, class_name: "Welcomes::Settings", dependent: :delete

  has_many :server_channels, dependent: :destroy
  has_many :server_roles, dependent: :delete_all

  validates :discord_id, presence: true, uniqueness: true

  def self.configured_ids_among(discord_ids)
    where(discord_id: discord_ids).pluck(:discord_id)
  end

  def icon_url
    Discord::CdnUrl.guild_icon(discord_id, icon_hash)
  end
end
