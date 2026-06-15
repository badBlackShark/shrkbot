class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    # ponytail: global key/value flags (one row each). A KV table so future
    # bot-wide flags don't each need a migration; not per-server (that's
    # ServerConfiguration). First use: owner_error_dms.
    create_table :settings, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.string :key, null: false
      t.string :value
      t.timestamps
    end
    add_index :settings, :key, unique: true
  end
end
