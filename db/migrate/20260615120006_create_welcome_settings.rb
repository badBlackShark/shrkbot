class CreateWelcomeSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :welcome_settings, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :server_configuration, null: false, foreign_key: true, type: :string, index: {unique: true}
      t.bigint :channel_id
      t.text :join_message
      t.text :leave_message
      t.timestamps
    end

    reversible do |dir|
      dir.up { execute "ALTER TABLE welcome_settings ALTER COLUMN id SET DEFAULT ('wls_' || gen_random_uuid())" }
    end
  end
end
