# frozen_string_literal: true

class AddNewAccountAgeDaysToModerationSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :moderation_settings, :new_account_age_days, :integer, null: false, default: 30

    add_check_constraint :moderation_settings,
      "new_account_age_days >= 1 AND new_account_age_days <= 365",
      name: "moderation_settings_new_account_age_days_check"
  end
end
