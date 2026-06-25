# frozen_string_literal: true

class AddOnboardedAtToServerConfigurations < ActiveRecord::Migration[8.1]
  def change
    add_column :server_configurations, :onboarded_at, :datetime
  end
end
