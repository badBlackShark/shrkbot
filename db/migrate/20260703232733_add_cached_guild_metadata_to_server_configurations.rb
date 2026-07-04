# frozen_string_literal: true

class AddCachedGuildMetadataToServerConfigurations < ActiveRecord::Migration[8.1]
  def change
    add_column :server_configurations, :name, :string
    add_column :server_configurations, :icon_hash, :string
    add_column :server_configurations, :member_count, :integer
  end
end
