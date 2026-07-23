# frozen_string_literal: true

class ServerConfiguration < ApplicationRecord
  has_many :plugin_activations, dependent: :delete_all
  has_many :plugins, through: :plugin_activations

  has_one :logging_setting, dependent: :delete
  has_one :role_setting, class_name: "Roles::Settings", dependent: :destroy
  has_one :welcome_settings, class_name: "Welcomes::Settings", dependent: :delete
  has_one :moderation_settings, class_name: "Moderation::Settings", dependent: :delete
  has_one :spam_protection_settings, class_name: "Moderation::SpamProtection::Settings", dependent: :delete
  has_one :image_scanning_settings, class_name: "Moderation::ImageScanning::Settings", dependent: :delete
  has_one :lfg_settings, class_name: "Lfg::Settings", dependent: :destroy
  has_many :lfg_messages, class_name: "Lfg::Message", dependent: :delete_all

  has_many :phash_confirmations, class_name: "Moderation::PhashConfirmation", dependent: :delete_all

  has_many :notifications, dependent: :delete_all
  has_many :server_channels, dependent: :destroy
  has_many :server_roles, dependent: :delete_all

  validates :discord_id, presence: true, uniqueness: true

  def self.configured_ids_among(discord_ids)
    where(discord_id: discord_ids).pluck(:discord_id)
  end

  def icon_url
    Bot::Discord::CdnUrl.guild_icon(discord_id, icon_hash)
  end

  def enabled_plugin_keys
    plugins.enabled.pluck(:key).map(&:to_sym).to_set
  end
end
