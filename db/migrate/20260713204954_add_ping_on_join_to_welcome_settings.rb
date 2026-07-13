# frozen_string_literal: true

class AddPingOnJoinToWelcomeSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :welcome_settings, :ping_on_join, :boolean, null: false, default: true
  end
end
