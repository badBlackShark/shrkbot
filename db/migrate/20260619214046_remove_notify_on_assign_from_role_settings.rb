class RemoveNotifyOnAssignFromRoleSettings < ActiveRecord::Migration[8.1]
  def change
    remove_column :role_settings, :notify_on_assign, :boolean, null: false, default: false
  end
end
