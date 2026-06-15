# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_15_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "assignable_roles", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "emoji"
    t.string "label"
    t.integer "position", default: 0, null: false
    t.bigint "role_id", null: false
    t.string "role_setting_id", null: false
    t.datetime "updated_at", null: false
    t.index ["role_setting_id", "role_id"], name: "index_assignable_roles_on_role_setting_id_and_role_id", unique: true
    t.index ["role_setting_id"], name: "index_assignable_roles_on_role_setting_id"
  end

  create_table "logging_settings", id: :string, force: :cascade do |t|
    t.bigint "channel_id"
    t.datetime "created_at", null: false
    t.string "server_configuration_id", null: false
    t.datetime "updated_at", null: false
    t.index ["server_configuration_id"], name: "index_logging_settings_on_server_configuration_id", unique: true
  end

  create_table "plugin_activations", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false, null: false
    t.string "plugin_id", null: false
    t.string "server_configuration_id", null: false
    t.datetime "updated_at", null: false
    t.index ["plugin_id"], name: "index_plugin_activations_on_plugin_id"
    t.index ["server_configuration_id", "plugin_id"], name: "idx_on_server_configuration_id_plugin_id_3b76ab42ac", unique: true
    t.index ["server_configuration_id"], name: "index_plugin_activations_on_server_configuration_id"
  end

  create_table "plugins", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "default_enabled", default: false, null: false
    t.text "description"
    t.string "key", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_plugins_on_key", unique: true
  end

  create_table "reminders", id: :string, force: :cascade do |t|
    t.bigint "channel_id", null: false
    t.datetime "created_at", null: false
    t.boolean "deliver_via_dm", default: false, null: false
    t.text "message", null: false
    t.datetime "remind_at", null: false
    t.bigint "server_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["remind_at"], name: "index_reminders_on_remind_at"
  end

  create_table "role_settings", id: :string, force: :cascade do |t|
    t.bigint "channel_id"
    t.datetime "created_at", null: false
    t.boolean "log_on_assign", default: false, null: false
    t.bigint "message_id"
    t.boolean "notify_on_assign", default: false, null: false
    t.string "server_configuration_id", null: false
    t.datetime "updated_at", null: false
    t.index ["server_configuration_id"], name: "index_role_settings_on_server_configuration_id", unique: true
  end

  create_table "server_configurations", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "discord_id", null: false
    t.boolean "force_dm_reminders", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["discord_id"], name: "index_server_configurations_on_discord_id", unique: true
  end

  create_table "welcome_settings", id: :string, force: :cascade do |t|
    t.bigint "channel_id"
    t.datetime "created_at", null: false
    t.text "join_message"
    t.text "leave_message"
    t.string "server_configuration_id", null: false
    t.datetime "updated_at", null: false
    t.index ["server_configuration_id"], name: "index_welcome_settings_on_server_configuration_id", unique: true
  end

  add_foreign_key "assignable_roles", "role_settings"
  add_foreign_key "logging_settings", "server_configurations"
  add_foreign_key "plugin_activations", "plugins"
  add_foreign_key "plugin_activations", "server_configurations"
  add_foreign_key "role_settings", "server_configurations"
  add_foreign_key "welcome_settings", "server_configurations"
end
