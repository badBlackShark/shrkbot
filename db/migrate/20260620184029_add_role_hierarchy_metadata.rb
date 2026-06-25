# frozen_string_literal: true

class AddRoleHierarchyMetadata < ActiveRecord::Migration[8.1]
  def change
    add_column :server_roles, :position, :integer
    add_column :server_roles, :managed, :boolean, null: false, default: false
    add_column :server_configurations, :bot_role_position, :integer
  end
end
