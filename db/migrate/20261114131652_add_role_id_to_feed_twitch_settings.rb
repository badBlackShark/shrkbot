# frozen_string_literal: true

class AddRoleIdToFeedTwitchSettings < ActiveRecord::Migration[8.1]
  def change
    add_column :feed_twitch_settings, :role_id, :bigint
  end
end
