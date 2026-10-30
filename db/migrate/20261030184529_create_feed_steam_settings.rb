# frozen_string_literal: true

class CreateFeedSteamSettings < ActiveRecord::Migration[8.1]
  LANGUAGES_CHECK = "languages <@ ARRAY['af', 'als', 'am', 'an', 'ar', 'arz', 'as', 'ast', 'av', 'az', 'azb', 'ba', 'bar', 'bcl', 'be', 'bg', 'bh', 'bn', 'bo', 'bpy', 'br', 'bs', 'bxr', 'ca', 'cbk', 'ce', 'ceb', 'ckb', 'co', 'cs', 'cv', 'cy', 'da', 'de', 'diq', 'dsb', 'dty', 'dv', 'el', 'eml', 'en', 'eo', 'es', 'et', 'eu', 'fa', 'fi', 'fr', 'frr', 'fy', 'ga', 'gd', 'gl', 'gn', 'gom', 'gu', 'gv', 'he', 'hi', 'hif', 'hr', 'hsb', 'ht', 'hu', 'hy', 'ia', 'id', 'ie', 'ilo', 'io', 'is', 'it', 'ja', 'jbo', 'jv', 'ka', 'kk', 'km', 'kn', 'ko', 'krc', 'ku', 'kv', 'kw', 'ky', 'la', 'lb', 'lez', 'li', 'lmo', 'lo', 'lrc', 'lt', 'lv', 'mai', 'mg', 'mhr', 'min', 'mk', 'ml', 'mn', 'mr', 'mrj', 'ms', 'mt', 'mwl', 'my', 'myv', 'mzn', 'nah', 'nap', 'nds', 'ne', 'new', 'nl', 'nn', 'no', 'oc', 'or', 'os', 'pa', 'pam', 'pfl', 'pl', 'pms', 'pnb', 'ps', 'pt', 'qu', 'rm', 'ro', 'ru', 'rue', 'sa', 'sah', 'sc', 'scn', 'sco', 'sd', 'sh', 'si', 'sk', 'sl', 'so', 'sq', 'sr', 'su', 'sv', 'sw', 'ta', 'te', 'tg', 'th', 'tk', 'tl', 'tr', 'tt', 'tyv', 'ug', 'uk', 'ur', 'uz', 'vec', 'vep', 'vi', 'vls', 'vo', 'wa', 'war', 'wuu', 'xal', 'xmf', 'yi', 'yo', 'yue', 'zh']::character varying[]"

  def up
    safety_assured do
      create_table :feed_steam_settings, id: false do |t|
        t.string :id, null: false, primary_key: true
        t.references :subscription, null: false, type: :string, index: {unique: true}, foreign_key: {to_table: :feed_subscriptions}
        t.bigint :role_id
        t.string :body_length, null: false, default: "preview"
        t.string :languages, array: true, default: [], null: false
        t.timestamps
      end
      execute "ALTER TABLE feed_steam_settings ALTER COLUMN id SET DEFAULT ('fss_' || gen_random_uuid())"
      execute "ALTER TABLE feed_steam_settings ADD CONSTRAINT feed_steam_settings_body_length_check CHECK (body_length IN ('preview', 'full'))"
      execute "ALTER TABLE feed_steam_settings ADD CONSTRAINT feed_steam_settings_languages_check CHECK (#{LANGUAGES_CHECK})"

      execute <<~SQL
        INSERT INTO feed_steam_settings (subscription_id, role_id, body_length, languages, created_at, updated_at)
        SELECT s.id, s.role_id, s.body_length, s.languages, NOW(), NOW()
        FROM feed_subscriptions s
        JOIN integration_watches w ON w.id = s.watch_id
        WHERE w.watcher = 'Integrations::Steam::NewsWatcher'
      SQL

      execute "ALTER TABLE feed_subscriptions DROP CONSTRAINT IF EXISTS feed_subscriptions_body_length_check"
      execute "ALTER TABLE feed_subscriptions DROP CONSTRAINT IF EXISTS feed_subscriptions_languages_check"
      execute "ALTER TABLE feed_subscriptions DROP COLUMN role_id, DROP COLUMN body_length, DROP COLUMN languages"
    end
  end

  def down
    safety_assured do
      execute <<~SQL
        ALTER TABLE feed_subscriptions
          ADD COLUMN role_id bigint,
          ADD COLUMN body_length varchar NOT NULL DEFAULT 'preview',
          ADD COLUMN languages varchar[] NOT NULL DEFAULT '{}'
      SQL
      execute <<~SQL
        UPDATE feed_subscriptions s
        SET role_id = f.role_id, body_length = f.body_length, languages = f.languages
        FROM feed_steam_settings f
        WHERE f.subscription_id = s.id
      SQL
      execute "ALTER TABLE feed_subscriptions ADD CONSTRAINT feed_subscriptions_body_length_check CHECK (body_length IN ('preview', 'full'))"
      execute "ALTER TABLE feed_subscriptions ADD CONSTRAINT feed_subscriptions_languages_check CHECK (#{LANGUAGES_CHECK})"
      drop_table :feed_steam_settings
    end
  end
end
