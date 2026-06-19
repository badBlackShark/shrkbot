class RemovePluginDefaultEnabled < ActiveRecord::Migration[8.1]
  def change
    remove_column :plugins, :default_enabled, :boolean, null: false, default: false
  end
end
