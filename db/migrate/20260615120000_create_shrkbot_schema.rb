class CreateShrkbotSchema < ActiveRecord::Migration[8.1]
  # PKs/internal FKs are prefixed-UUID strings (see PrefixedId). Discord snowflakes
  # (discord_id, user_id, channel_id, role_id, message_id, server_id) stay bigint.
  def change
    create_table :server_configurations, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.bigint :discord_id, null: false
      t.boolean :force_dm_reminders, null: false, default: false
      t.timestamps
    end
    add_index :server_configurations, :discord_id, unique: true

    create_table :plugins, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.string :key, null: false
      t.string :name, null: false
      t.text :description
      t.boolean :default_enabled, null: false, default: false
      t.timestamps
    end
    add_index :plugins, :key, unique: true

    create_table :plugin_activations, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :server_configuration, null: false, foreign_key: true, type: :string
      t.references :plugin, null: false, foreign_key: true, type: :string
      t.boolean :enabled, null: false, default: false
      t.timestamps
    end
    add_index :plugin_activations, %i[server_configuration_id plugin_id], unique: true

    create_table :logging_settings, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :server_configuration, null: false, foreign_key: true, type: :string, index: {unique: true}
      t.bigint :channel_id
      t.timestamps
    end

    create_table :role_settings, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :server_configuration, null: false, foreign_key: true, type: :string, index: {unique: true}
      t.bigint :channel_id
      t.bigint :message_id
      t.boolean :notify_on_assign, null: false, default: false
      t.boolean :log_on_assign, null: false, default: false
      t.timestamps
    end

    create_table :assignable_roles, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :role_setting, null: false, foreign_key: true, type: :string
      t.bigint :role_id, null: false
      t.string :label
      t.string :description
      t.string :emoji
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :assignable_roles, %i[role_setting_id role_id], unique: true

    create_table :welcome_settings, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :server_configuration, null: false, foreign_key: true, type: :string, index: {unique: true}
      t.bigint :channel_id
      t.text :join_message
      t.text :leave_message
      t.timestamps
    end

    create_table :reminders, id: false do |t|
      t.string :id, null: false, primary_key: true
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
