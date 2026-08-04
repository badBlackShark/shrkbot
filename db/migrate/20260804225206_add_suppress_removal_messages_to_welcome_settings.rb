# frozen_string_literal: true

class AddSuppressRemovalMessagesToWelcomeSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :welcome_settings, :suppress_removal_messages, :boolean, default: false, null: false
  end
end
