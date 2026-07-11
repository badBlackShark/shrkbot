# frozen_string_literal: true

class AddPermissionsToServerRoles < ActiveRecord::Migration[8.1]
  def change
    add_column :server_roles, :permissions, :bigint, default: 0, null: false
  end
end
