# frozen_string_literal: true

class AddDiscordOrderingToServerChannels < ActiveRecord::Migration[8.1]
  def change
    add_column :server_channels, :position, :integer
    add_column :server_channels, :parent_id, :bigint
  end
end
