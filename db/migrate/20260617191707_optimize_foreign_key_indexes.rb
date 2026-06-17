class OptimizeForeignKeyIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :reminders, :user_id

    remove_index :plugin_activations, :server_configuration_id
    remove_index :assignable_roles, :role_setting_id
  end
end
