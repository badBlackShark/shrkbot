# frozen_string_literal: true

class AddConfirmedPunishmentToImageScanningSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :image_scanning_settings, :confirmed_punishment, :string, null: false, default: "none"
    add_column :image_scanning_settings, :confirmed_timeout_seconds, :integer, null: false, default: 3600

    add_check_constraint :image_scanning_settings,
      "confirmed_punishment IN ('none', 'timeout', 'kick', 'ban')",
      name: "image_scanning_settings_confirmed_punishment_check"
    add_check_constraint :image_scanning_settings,
      "confirmed_timeout_seconds >= 60 AND confirmed_timeout_seconds <= 2419200",
      name: "image_scanning_settings_confirmed_timeout_seconds_check"
  end
end
