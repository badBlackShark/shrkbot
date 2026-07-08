# frozen_string_literal: true

class CreateImageScanningSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :image_scanning_settings, id: false do |t|
      t.string :id, null: false, primary_key: true
      t.references :server_configuration, null: false, foreign_key: true, type: :string, index: {unique: true}
      t.string :sensitivity, null: false, default: "standard"
      t.string :action, null: false, default: "delete"
      t.string :punishment, null: false, default: "none"
      t.integer :timeout_seconds, null: false, default: 3600
      t.text :custom_keywords, array: true, null: false, default: []
      t.integer :custom_keyword_min_hits, null: false, default: 2
      t.timestamps
    end

    add_check_constraint :image_scanning_settings, "sensitivity IN ('relaxed', 'standard', 'strict')", name: "image_scanning_settings_sensitivity_check"
    add_check_constraint :image_scanning_settings, "action IN ('none', 'delete')", name: "image_scanning_settings_action_check"
    add_check_constraint :image_scanning_settings, "punishment IN ('none', 'timeout', 'kick', 'ban')", name: "image_scanning_settings_punishment_check"
    add_check_constraint :image_scanning_settings, "timeout_seconds >= 60 AND timeout_seconds <= 2419200", name: "image_scanning_settings_timeout_seconds_check"
    add_check_constraint :image_scanning_settings, "cardinality(custom_keywords) <= 200", name: "image_scanning_settings_custom_keywords_count_check"
    add_check_constraint :image_scanning_settings, "custom_keyword_min_hits >= 1 AND (cardinality(custom_keywords) = 0 OR custom_keyword_min_hits <= cardinality(custom_keywords))", name: "image_scanning_settings_min_hits_check"

    reversible do |dir|
      dir.up { execute "ALTER TABLE image_scanning_settings ALTER COLUMN id SET DEFAULT ('iss_' || gen_random_uuid())" }
    end
  end
end
