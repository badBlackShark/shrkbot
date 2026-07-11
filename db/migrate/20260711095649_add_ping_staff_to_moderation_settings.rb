# frozen_string_literal: true

class AddPingStaffToModerationSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :moderation_settings, :ping_staff, :boolean, null: false, default: true
  end
end
