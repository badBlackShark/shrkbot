class CreateServerConfigurations < ActiveRecord::Migration[8.1]
  def change
    create_table :server_configurations, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.bigint :discord_id, null: false
      t.boolean :force_dm_reminders, null: false, default: false
      t.timestamps
    end
    add_index :server_configurations, :discord_id, unique: true

    reversible do |dir|
      dir.up { execute "ALTER TABLE server_configurations ALTER COLUMN id SET DEFAULT ('srv_' || gen_random_uuid())" }
    end
  end
end
