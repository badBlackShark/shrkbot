class CreatePluginActivations < ActiveRecord::Migration[8.1]
  def change
    create_table :plugin_activations, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :server_configuration, null: false, foreign_key: true, type: :string
      t.references :plugin, null: false, foreign_key: true, type: :string
      t.boolean :enabled, null: false, default: false
      t.timestamps
    end
    add_index :plugin_activations, %i[server_configuration_id plugin_id], unique: true

    reversible do |dir|
      dir.up { execute "ALTER TABLE plugin_activations ALTER COLUMN id SET DEFAULT ('pac_' || gen_random_uuid())" }
    end
  end
end
