# frozen_string_literal: true

class DropIntegrationSeenItems < ActiveRecord::Migration[8.1]
  def change
    drop_table :integration_seen_items, id: :string, default: -> { "('its_'::text || gen_random_uuid())" } do |t|
      t.string :watch_id, null: false
      t.string :external_id, null: false
      t.timestamps
      t.index [:watch_id, :external_id], unique: true
      t.foreign_key :integration_watches, column: :watch_id
    end
  end
end
