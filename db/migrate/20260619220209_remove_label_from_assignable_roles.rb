class RemoveLabelFromAssignableRoles < ActiveRecord::Migration[8.1]
  def change
    remove_column :assignable_roles, :label, :string
  end
end
