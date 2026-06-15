class CreateShrkbotSchema < ActiveRecord::Migration[8.1]
  def change
    create_table :server_configurations do |t|
      t.bigint :discord_id, null: false
      t.boolean :force_dm_reminders, null: false, default: false
      t.timestamps
    end
    add_index :server_configurations, :discord_id, unique: true

    create_table :plugins do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.text :description
      t.boolean :default_enabled, null: false, default: false
      t.timestamps
    end
    add_index :plugins, :key, unique: true

    create_table :plugin_activations do |t|
      t.references :server_configuration, null: false, foreign_key: true
      t.references :plugin, null: false, foreign_key: true
      t.boolean :enabled, null: false, default: false
      t.timestamps
    end
    add_index :plugin_activations, %i[server_configuration_id plugin_id], unique: true

    create_table :logging_settings do |t|
      t.references :server_configuration, null: false, foreign_key: true, index: { unique: true }
      t.bigint :channel_id
      t.timestamps
    end

    create_table :role_settings do |t|
      t.references :server_configuration, null: false, foreign_key: true, index: { unique: true }
      t.bigint :channel_id
      t.bigint :message_id
      t.boolean :notify_on_assign, null: false, default: false
      t.boolean :log_on_assign, null: false, default: false
      t.timestamps
    end

    create_table :assignable_roles do |t|
      t.references :role_setting, null: false, foreign_key: true
      t.bigint :role_id, null: false
      t.string :label
      t.string :description
      t.string :emoji
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :assignable_roles, %i[role_setting_id role_id], unique: true

    create_table :welcome_settings do |t|
      t.references :server_configuration, null: false, foreign_key: true, index: { unique: true }
      t.bigint :channel_id
      t.text :join_message
      t.text :leave_message
      t.timestamps
    end

    create_table :reminders do |t|
      t.bigint :server_id # null = DM reminder
      t.bigint :user_id, null: false
      t.bigint :channel_id, null: false
      t.datetime :remind_at, null: false
      t.text :message, null: false
      t.boolean :deliver_via_dm, null: false, default: false
      t.timestamps
    end
    add_index :reminders, :remind_at
  end
end
