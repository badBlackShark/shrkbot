# frozen_string_literal: true

class CreateBespokePluginGrants < ActiveRecord::Migration[8.1]
  def change
    create_table :bespoke_plugin_grants, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :server_configuration, null: false, foreign_key: true, type: :string, index: false
      t.string :plugin_key, null: false
      t.timestamps
    end

    add_index :bespoke_plugin_grants,
      [:server_configuration_id, :plugin_key],
      unique: true,
      name: "index_bespoke_plugin_grants_on_server_and_plugin_key"

    reversible do |dir|
      dir.up { safety_assured { execute "ALTER TABLE bespoke_plugin_grants ALTER COLUMN id SET DEFAULT ('bpg_' || gen_random_uuid())" } }
    end
  end
end
