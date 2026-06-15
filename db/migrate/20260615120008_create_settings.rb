class CreateSettings < ActiveRecord::Migration[8.1]
  # Global key/value flags (one row each) — bot-wide, not per-server. First use:
  # owner_error_dms.
  def change
    create_table :settings, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.string :key, null: false
      t.string :value
      t.timestamps
    end
    add_index :settings, :key, unique: true

    reversible do |dir|
      dir.up { execute "ALTER TABLE settings ALTER COLUMN id SET DEFAULT ('set_' || gen_random_uuid())" }
    end
  end
end
