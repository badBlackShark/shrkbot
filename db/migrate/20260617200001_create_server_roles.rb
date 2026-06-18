class CreateServerRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :server_roles, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :server_configuration, null: false, foreign_key: true, type: :string, index: false
      t.bigint :discord_id, null: false
      t.string :name, null: false
      t.timestamps
      t.index [:server_configuration_id, :discord_id], unique: true
    end

    reversible do |dir|
      dir.up { execute "ALTER TABLE server_roles ALTER COLUMN id SET DEFAULT ('srl_' || gen_random_uuid())" }
    end
  end
end
