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

ActiveRecord::Schema[8.1].define(version: 2026_07_13_170330) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "assignable_roles", id: :string, default: -> { "('asr_'::text || gen_random_uuid())" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "emoji"
    t.integer "position", default: 0, null: false
    t.bigint "role_id", null: false
    t.string "role_set_id", null: false
    t.datetime "updated_at", null: false
    t.index ["role_set_id", "role_id"], name: "index_assignable_roles_on_role_set_id_and_role_id", unique: true
  end

  create_table "bot_settings", id: :string, default: -> { "('bst_'::text || gen_random_uuid())" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.string "value"
    t.index ["key"], name: "index_bot_settings_on_key", unique: true
  end

  create_table "channel_overwrites", id: :string, default: -> { "('cov_'::text || gen_random_uuid())" }, force: :cascade do |t|
    t.bigint "allow", default: 0, null: false
    t.datetime "created_at", null: false
    t.bigint "deny", default: 0, null: false
    t.string "server_channel_id", null: false
    t.bigint "target_id", null: false
    t.string "target_type", null: false
    t.datetime "updated_at", null: false
    t.index ["server_channel_id", "target_id"], name: "index_channel_overwrites_on_server_channel_id_and_target_id", unique: true
    t.check_constraint "target_type::text = ANY (ARRAY['role'::character varying::text, 'member'::character varying::text])", name: "channel_overwrites_target_type_check"
  end

  create_table "image_scanning_settings", id: :string, default: -> { "('iss_'::text || gen_random_uuid())" }, force: :cascade do |t|
    t.string "action", default: "delete", null: false
    t.string "confirmed_punishment", default: "none", null: false
    t.integer "confirmed_timeout_seconds", default: 3600, null: false
    t.datetime "created_at", null: false
    t.integer "custom_keyword_min_hits", default: 2, null: false
    t.text "custom_keywords", default: [], null: false, array: true
    t.string "punishment", default: "none", null: false
    t.string "sensitivity", default: "standard", null: false
    t.string "server_configuration_id", null: false
    t.integer "timeout_seconds", default: 3600, null: false
    t.datetime "updated_at", null: false
    t.index ["server_configuration_id"], name: "index_image_scanning_settings_on_server_configuration_id", unique: true
    t.check_constraint "action::text = ANY (ARRAY['none'::character varying, 'delete'::character varying]::text[])", name: "image_scanning_settings_action_check"
    t.check_constraint "cardinality(custom_keywords) <= 200", name: "image_scanning_settings_custom_keywords_count_check"
    t.check_constraint "confirmed_punishment::text = ANY (ARRAY['none'::character varying, 'timeout'::character varying, 'kick'::character varying, 'ban'::character varying]::text[])", name: "image_scanning_settings_confirmed_punishment_check"
    t.check_constraint "confirmed_timeout_seconds >= 60 AND confirmed_timeout_seconds <= 2419200", name: "image_scanning_settings_confirmed_timeout_seconds_check"
    t.check_constraint "custom_keyword_min_hits >= 1 AND (cardinality(custom_keywords) = 0 OR custom_keyword_min_hits <= cardinality(custom_keywords))", name: "image_scanning_settings_min_hits_check"
    t.check_constraint "punishment::text = ANY (ARRAY['none'::character varying, 'timeout'::character varying, 'kick'::character varying, 'ban'::character varying]::text[])", name: "image_scanning_settings_punishment_check"
    t.check_constraint "sensitivity::text = ANY (ARRAY['relaxed'::character varying, 'standard'::character varying, 'strict'::character varying]::text[])", name: "image_scanning_settings_sensitivity_check"
    t.check_constraint "timeout_seconds >= 60 AND timeout_seconds <= 2419200", name: "image_scanning_settings_timeout_seconds_check"
  end

  create_table "logging_settings", id: :string, default: -> { "('lgs_'::text || gen_random_uuid())" }, force: :cascade do |t|
    t.bigint "channel_id"
    t.datetime "created_at", null: false
    t.jsonb "enabled_actions", default: {}, null: false
    t.string "server_configuration_id", null: false
    t.datetime "updated_at", null: false
    t.index ["server_configuration_id"], name: "index_logging_settings_on_server_configuration_id", unique: true
  end

  create_table "moderation_settings", id: :string, default: -> { "('mds_'::text || gen_random_uuid())" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "new_account_age_days", default: 30, null: false
    t.boolean "ping_staff", default: true, null: false
    t.string "server_configuration_id", null: false
    t.bigint "staff_role_id"
    t.datetime "updated_at", null: false
    t.index ["server_configuration_id"], name: "index_moderation_settings_on_server_configuration_id", unique: true
    t.check_constraint "new_account_age_days >= 1 AND new_account_age_days <= 365", name: "moderation_settings_new_account_age_days_check"
  end

  create_table "moderation_verdicts", id: :string, default: -> { "('mvr_'::text || gen_random_uuid())" }, force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.bigint "discord_user_id", null: false
    t.bigint "log_channel_id"
    t.bigint "log_message_id"
    t.string "phash"
    t.string "punishment", default: "none", null: false
    t.datetime "reversed_at"
    t.string "server_configuration_id", null: false
    t.datetime "updated_at", null: false
    t.index ["discord_user_id"], name: "index_moderation_verdicts_on_discord_user_id"
    t.index ["server_configuration_id", "created_at"], name: "idx_on_server_configuration_id_created_at_47198f0f26"
    t.check_constraint "action::text = ANY (ARRAY['flag_for_review'::character varying, 'remove'::character varying]::text[])", name: "moderation_verdicts_action_check"
    t.check_constraint "punishment::text = ANY (ARRAY['none'::character varying, 'timeout'::character varying, 'kick'::character varying, 'ban'::character varying]::text[])", name: "moderation_verdicts_punishment_check"
  end

  create_table "notifications", id: :string, default: -> { "('ntf_'::text || gen_random_uuid())" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}, null: false
    t.datetime "dismissed_at"
    t.string "kind", null: false
    t.datetime "read_at"
    t.string "server_configuration_id", null: false
    t.datetime "updated_at", null: false
    t.index ["server_configuration_id", "created_at"], name: "index_notifications_on_server_configuration_id_and_created_at"
  end

  create_table "phash_confirmations", id: :string, default: -> { "('phc_'::text || gen_random_uuid())" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "phash_id", null: false
    t.string "server_configuration_id", null: false
    t.datetime "updated_at", null: false
    t.string "verdict", null: false
    t.index ["phash_id", "server_configuration_id"], name: "idx_on_phash_id_server_configuration_id_693185e6e1", unique: true
    t.index ["server_configuration_id"], name: "index_phash_confirmations_on_server_configuration_id"
    t.check_constraint "verdict::text = ANY (ARRAY['confirmed'::character varying, 'dismissed'::character varying]::text[])", name: "phash_confirmations_verdict_check"
  end

  create_table "phashes", id: :string, default: -> { "('phs_'::text || gen_random_uuid())" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "global_scam", default: false, null: false
    t.datetime "last_seen_at", null: false
    t.string "phash", limit: 16, null: false
    t.datetime "updated_at", null: false
    t.index ["global_scam"], name: "index_phashes_on_global_scam", where: "global_scam"
    t.index ["phash"], name: "index_phashes_on_phash", unique: true
  end

  create_table "plugin_activations", id: :string, default: -> { "('pac_'::text || gen_random_uuid())" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false, null: false
    t.string "plugin_id", null: false
    t.string "server_configuration_id", null: false
    t.datetime "updated_at", null: false
    t.index ["plugin_id"], name: "index_plugin_activations_on_plugin_id"
    t.index ["server_configuration_id", "plugin_id"], name: "idx_on_server_configuration_id_plugin_id_3b76ab42ac", unique: true
  end

  create_table "plugins", id: :string, default: -> { "('plg_'::text || gen_random_uuid())" }, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_plugins_on_key", unique: true
  end

  create_table "reminders", id: :string, default: -> { "('rmd_'::text || gen_random_uuid())" }, force: :cascade do |t|
    t.bigint "channel_id", null: false
    t.datetime "created_at", null: false
    t.boolean "deliver_via_dm", default: false, null: false
    t.text "message", null: false
    t.datetime "remind_at", null: false
    t.bigint "server_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["remind_at"], name: "index_reminders_on_remind_at"
    t.index ["user_id"], name: "index_reminders_on_user_id"
  end

  create_table "role_sets", id: :string, default: -> { "('rst_'::text || gen_random_uuid())" }, force: :cascade do |t|
    t.bigint "channel_override"
    t.datetime "created_at", null: false
    t.bigint "message_id"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "role_setting_id", null: false
    t.string "selection_mode", null: false
    t.datetime "updated_at", null: false
    t.index ["role_setting_id"], name: "index_role_sets_on_role_setting_id"
    t.check_constraint "selection_mode::text = ANY (ARRAY['single'::character varying::text, 'multi'::character varying::text])", name: "role_sets_selection_mode_check"
  end

  create_table "role_settings", id: :string, default: -> { "('rls_'::text || gen_random_uuid())" }, force: :cascade do |t|
    t.bigint "channel_id"
    t.datetime "created_at", null: false
    t.string "server_configuration_id", null: false
    t.datetime "updated_at", null: false
    t.index ["server_configuration_id"], name: "index_role_settings_on_server_configuration_id", unique: true
  end

  create_table "server_channels", id: :string, default: -> { "('sch_'::text || gen_random_uuid())" }, force: :cascade do |t|
    t.integer "channel_type", null: false
    t.datetime "created_at", null: false
    t.bigint "discord_id", null: false
    t.string "name", null: false
    t.bigint "parent_id"
    t.integer "position"
    t.string "server_configuration_id", null: false
    t.datetime "updated_at", null: false
    t.index ["server_configuration_id", "discord_id"], name: "idx_on_server_configuration_id_discord_id_610352a54e", unique: true
  end

  create_table "server_configurations", id: :string, default: -> { "('srv_'::text || gen_random_uuid())" }, force: :cascade do |t|
    t.integer "bot_role_position"
    t.datetime "created_at", null: false
    t.bigint "discord_id", null: false
    t.boolean "force_dm_reminders", default: false, null: false
    t.string "icon_hash"
    t.integer "member_count"
    t.string "name"
    t.datetime "onboarded_at"
    t.datetime "updated_at", null: false
    t.index ["discord_id"], name: "index_server_configurations_on_discord_id", unique: true
  end

  create_table "server_roles", id: :string, default: -> { "('srl_'::text || gen_random_uuid())" }, force: :cascade do |t|
    t.integer "color", default: 0, null: false
    t.datetime "created_at", null: false
    t.bigint "discord_id", null: false
    t.boolean "managed", default: false, null: false
    t.string "name", null: false
    t.bigint "permissions", default: 0, null: false
    t.integer "position"
    t.string "server_configuration_id", null: false
    t.datetime "updated_at", null: false
    t.index ["server_configuration_id", "discord_id"], name: "index_server_roles_on_server_configuration_id_and_discord_id", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.text "description"
    t.string "key", null: false
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "spam_protection_settings", id: :string, default: -> { "('sps_'::text || gen_random_uuid())" }, force: :cascade do |t|
    t.string "action", default: "purge", null: false
    t.integer "channel_threshold", default: 4, null: false
    t.datetime "created_at", null: false
    t.boolean "match_symbol_only_messages", default: false, null: false
    t.string "punishment", default: "none", null: false
    t.string "server_configuration_id", null: false
    t.float "similarity", default: 1.0, null: false
    t.integer "timeout_seconds", default: 3600, null: false
    t.datetime "updated_at", null: false
    t.integer "window_seconds", default: 15, null: false
    t.index ["server_configuration_id"], name: "index_spam_protection_settings_on_server_configuration_id", unique: true
    t.check_constraint "action::text = ANY (ARRAY['purge'::character varying, 'notify_only'::character varying]::text[])", name: "spam_protection_settings_action_check"
    t.check_constraint "channel_threshold >= 2 AND channel_threshold <= 500", name: "spam_protection_settings_channel_threshold_check"
    t.check_constraint "punishment::text = ANY (ARRAY['none'::character varying, 'timeout'::character varying, 'kick'::character varying, 'ban'::character varying]::text[])", name: "spam_protection_settings_punishment_check"
    t.check_constraint "similarity >= 0.75::double precision AND similarity <= 1.0::double precision", name: "spam_protection_settings_similarity_check"
    t.check_constraint "timeout_seconds >= 60 AND timeout_seconds <= 2419200", name: "spam_protection_settings_timeout_seconds_check"
    t.check_constraint "window_seconds >= 1 AND window_seconds <= 60", name: "spam_protection_settings_window_seconds_check"
  end

  create_table "users", id: :string, default: -> { "('usr_'::text || gen_random_uuid())" }, force: :cascade do |t|
    t.string "avatar"
    t.datetime "created_at", null: false
    t.bigint "discord_id", null: false
    t.string "display_name"
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["discord_id"], name: "index_users_on_discord_id", unique: true
  end

  create_table "welcome_settings", id: :string, default: -> { "('wls_'::text || gen_random_uuid())" }, force: :cascade do |t|
    t.bigint "channel_id"
    t.datetime "created_at", null: false
    t.text "join_message"
    t.text "leave_message"
    t.string "server_configuration_id", null: false
    t.datetime "updated_at", null: false
    t.index ["server_configuration_id"], name: "index_welcome_settings_on_server_configuration_id", unique: true
  end

  add_foreign_key "assignable_roles", "role_sets"
  add_foreign_key "channel_overwrites", "server_channels"
  add_foreign_key "image_scanning_settings", "server_configurations"
  add_foreign_key "logging_settings", "server_configurations"
  add_foreign_key "moderation_settings", "server_configurations"
  add_foreign_key "moderation_verdicts", "server_configurations"
  add_foreign_key "notifications", "server_configurations"
  add_foreign_key "phash_confirmations", "phashes"
  add_foreign_key "phash_confirmations", "server_configurations"
  add_foreign_key "plugin_activations", "plugins"
  add_foreign_key "plugin_activations", "server_configurations"
  add_foreign_key "role_sets", "role_settings"
  add_foreign_key "role_settings", "server_configurations"
  add_foreign_key "server_channels", "server_configurations"
  add_foreign_key "server_roles", "server_configurations"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "spam_protection_settings", "server_configurations"
  add_foreign_key "welcome_settings", "server_configurations"
end
