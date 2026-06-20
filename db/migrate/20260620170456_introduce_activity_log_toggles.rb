class IntroduceActivityLogToggles < ActiveRecord::Migration[8.1]
  def change
    add_column :logging_settings, :enabled_actions, :jsonb, null: false, default: {}
    remove_column :role_settings, :log_on_assign, :boolean, null: false, default: false
  end
end
