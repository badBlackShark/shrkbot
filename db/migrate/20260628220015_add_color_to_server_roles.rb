# frozen_string_literal: true

class AddColorToServerRoles < ActiveRecord::Migration[8.1]
  def change
    add_column :server_roles, :color, :integer, default: 0, null: false
  end
end
